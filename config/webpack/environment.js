const { parse, resolve } = require('path');
const { environment } = require('@rails/webpacker');
const { sync: glob } = require('fast-glob');
const RailsI18nWebpackPlugin = require('@18f/identity-rails-i18n-webpack-plugin');

glob('app/components/*.js').forEach((path) => {
  environment.entry[parse(path).name] = resolve(path);
});

environment.loaders.delete('file');
environment.loaders.delete('nodeModules');
environment.loaders.delete('moduleSass');
environment.loaders.delete('moduleCss');
environment.loaders.delete('css');
environment.loaders.delete('sass');

// Note: Because chunk splitting is enabled by default as of Webpacker 6+, this line can be removed
// when upgrading.
environment.splitChunks();

// Some files under `node_modules` should be compiled by Babel:
// 1. Yarn workspace package symlinks, by package name starting with `@18f/identity-`.
// 2. Specific dependencies that don't compile their own code to run safely in legacy browsers.
const babelLoader = environment.loaders.get('babel');
babelLoader.include.push(
  /node_modules\/(@18f\/identity-|identity-style-guide|uswds|receptor|elem-dataset)/,
);
babelLoader.exclude = /node_modules\/(?!@18f\/identity-|identity-style-guide|uswds|receptor|elem-dataset)/;

const sourceMapLoader = {
  test: /\.js$/,
  include: /node_modules/,
  enforce: 'pre',
  use: ['source-map-loader'],
};
environment.loaders.append('sourceMap', sourceMapLoader);

environment.plugins.prepend('RailsI18nWebpackPlugin', new RailsI18nWebpackPlugin());

module.exports = environment;
