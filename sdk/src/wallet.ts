import { Psbt, Transaction, Network, TxOutput, address as addressUtils } from "bitcoinjs-lib";
import { ElectrsClient } from "./electrs";

import coinSelect = require('coinselect');

export interface Wallet {
    // NOTE: for now this should always return the same address
    getAddress(): Promise<string>;
    signPsbt(psbt: Psbt): Promise<Psbt>;
}

export async function createAndFundTransaction(electrsClient: ElectrsClient, wallet: Wallet, network: Network, txOutputs: Array<TxOutput>): Promise<Transaction> {
    const address = await wallet.getAddress();
    const utxos = await electrsClient.getAddressUtxos(address);

    const { inputs, outputs } = coinSelect(
        utxos.map(utxo => {
            return {
                txId: utxo.txid,
                vout: utxo.vout,
                value: utxo.value,
            }
        }),
        txOutputs.map(txOut => {
            return {
                address: addressUtils.fromOutputScript(txOut.script, network),
                value: txOut.value,
            }
        }),
        1
    );

    let psbt = new Psbt({ network })

    inputs.forEach(input =>
        psbt.addInput({
            hash: input.txId,
            index: input.vout,
            // TODO: determine these from electrs utxos
            nonWitnessUtxo: input.nonWitnessUtxo,
            witnessUtxo: input.witnessUtxo,
        })
    );

    const changeAddress = await wallet.getAddress();
    outputs.forEach(output => {
        // watch out, outputs may have been added that you need to provide
        // an output address/script for
        if (!output.address) {
            output.address = changeAddress;
        }

        psbt.addOutput({
            address: output.address,
            value: output.value,
        })
    });

    await wallet.signPsbt(psbt);
    return psbt.extractTransaction();
}