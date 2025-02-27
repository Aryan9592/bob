/**
 * Creating a sidebar enables you to:
 - create an ordered group of docs
 - render a sidebar for each doc of that group
 - provide next/previous navigation

 The sidebars can be generated from the filesystem, or explicitly defined here.

 Create as many sidebars as you want.
 */

// @ts-check

/** @type {import('@docusaurus/plugin-content-docs').SidebarsConfig} */
const sidebars = {
  // By default, Docusaurus generates a sidebar from the docs folder structure
  rootSidebar: [{type: 'autogenerated', dirName: '.'}],
  learnSidebar: [{type: 'autogenerated', dirName: 'learn'}],
  buildSidebar: [{type: 'autogenerated', dirName: 'build'}],
  apiSidebar: [
    {
      type: 'category',
      label: 'TypeScript API',
      collapsed: false,
      items: [
        "api/ts-sdk/modules",
        {
          type: 'category',
          label: 'Modules',
          items: [
            {
              type: 'autogenerated',
              dirName: 'api/ts-sdk/modules'
            }
          ]
        },
        {
          type: 'category',
          label: 'Interfaces',
          items: [
            {
              type: 'autogenerated',
              dirName: 'api/ts-sdk/interfaces'
            }
          ]
        },
        {
          type: 'category',
          label: 'Classes',
          items: [
            {
              type: 'autogenerated',
              dirName: 'api/ts-sdk/classes'
            }
          ]
        }
      ],
    }
  ],
  // guideSidebar: [{type: 'autogenerated', dirName: 'guide'}],
  // runSidebar: [{type: 'autogenerated', dirName: 'run'}],

  // But you can create a sidebar manually
  /*
  tutorialSidebar: [
    'intro',
    'hello',
    {
      type: 'category',
      label: 'Tutorial',
      items: ['tutorial-basics/create-a-document'],
    },
  ],
   */
};

module.exports = sidebars;
