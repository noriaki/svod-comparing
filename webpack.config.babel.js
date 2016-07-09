// -*- mode: js2-jsx; -*-
import 'babel-polyfill';
import webpack from 'webpack';
import path from 'path';

import ManifestPlugin from 'webpack-manifest-plugin';
import ExtractTextPlugin from 'extract-text-webpack-plugin';
import CleanWebpackPlugin from 'clean-webpack-plugin';

const DEBUG = !process.argv.includes('--release');
const VERBOSE = process.argv.includes('--verbose');

const fileName = DEBUG ? '[name]' : '[name]-[hash]';

const entry = {
  application: ['./app/frontend/javascripts/application.jsx'],
};

export default {
  cache: DEBUG,
  debug: DEBUG,
  entry,
  output: {
    path: path.resolve('public', 'assets'),
    filename: `${fileName}.js`,
    publicPath: DEBUG ? 'http://localhost:3500/assets/' : '/assets/',
  },
  devtool: DEBUG ? '#inline-source-map' : '#eval',
  plugins: [
    new ExtractTextPlugin(`${fileName}.css`),
    new webpack.optimize.OccurenceOrderPlugin(),
    new webpack.DefinePlugin({
      'process.env.NODE_ENV': JSON.stringify(
        process.env.NODE_ENV || (DEBUG ? 'development' : 'production')
      ),
    }),
    ...(DEBUG ? [
      new webpack.NoErrorsPlugin(),
    ] : [
      new ManifestPlugin({ fileName: 'webpack-manifest.json' }),
      new webpack.optimize.DedupePlugin(),
      new webpack.optimize.UglifyJsPlugin({
        compress: { screw_ie8: true, warnings: VERBOSE },
      }),
      new webpack.optimize.AggressiveMergingPlugin(),
      new CleanWebpackPlugin(['public/assets'], {
        root: path.resolve(), verbose: VERBOSE, dry: false,
      }),
    ]),
  ],
  module: {
    loaders: [
      {
        test: /\.jsx?$/,
        exclude: /node_modules/,
        loader: 'babel',
      },
      {
        test: /\.css$/,
        loader: ExtractTextPlugin.extract('style', 'css'),
      },
      {
        test: /\.s[ac]ss$/,
        loader: ExtractTextPlugin.extract('style', 'css!sass'),
      },
      {
        test: /\.svg(\?v=\d+\.\d+\.\d+)?$/,
        loader: 'url?mimetype=image/svg+xml',
      },
      {
        test: /\.woff(\d+)?(\?v=\d+\.\d+\.\d+)?$/,
        loader: 'url?mimetype=application/font-woff',
      },
      {
        test: /\.eot(\?v=\d+\.\d+\.\d+)?$/,
        loader: 'url?mimetype=application/font-woff',
      },
      {
        test: /\.ttf(\?v=\d+\.\d+\.\d+)?$/,
        loader: 'url?mimetype=application/font-woff',
      },
      {
        test: /\.(jpg|jpeg|png|gif)$/,
        loader: `file?name=${fileName}.[ext]`,
      },
    ],
  },
  resolve: {
    root: path.resolve('app', 'frontend'),
    extensions: ['', '.js', '.jsx', '.css', '.scss', '.sass'],
  },
  devServer: {
    headers: {
      'Access-Control-Allow-Origin': 'http://localhost:8081',
      'Access-Control-Allow-Credentials': 'true',
    },
  },
};
