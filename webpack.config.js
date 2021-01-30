'use strict';

const path = require('path');

const config = {
  target: 'node',
  entry: './lib/js/src/extension.bs.js',
  output: {
    path: path.join(__dirname, 'dist'),
    filename: 'app.bundle.js',
    libraryTarget: 'commonjs2'
  },
  devtool: 'source-map',
  externals: {
    vscode: 'commonjs vscode'
  }
};
module.exports = config;