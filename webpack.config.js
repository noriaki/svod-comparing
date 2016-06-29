const DEBUG = process.env.NODE_ENV === "development" || process.env.NODE_ENV === undefined;
const webpack = require('webpack');
const path = require('path');

const ManifestPlugin = require('webpack-manifest-plugin');
const ExtractTextPlugin = require('extract-text-webpack-plugin');
const CleanWebpackPlugin = require('clean-webpack-plugin');

const devtool = DEBUG ? "#inline-source-map" : '#eval';
const fileName = DEBUG ? '[name]' : '[name]-[hash]';
const publicPath = DEBUG ? 'http://localhost:3500/assets/' : '/assets/';

const entries = {
  application: ['./app/frontend/javascripts/application.jsx']
};

const plugins = [
  new ExtractTextPlugin(`${fileName}.css`)
];

if(DEBUG) {
  plugins.push(new webpack.NoErrorsPlugin());
} else {
  plugins.push(new ManifestPlugin({ fileName: 'webpack-manifest.json' }));
  plugins.push(new webpack.optimize.UglifyJsPlugin({ compress: { warnings: false } }));
  plugins.push(new CleanWebpackPlugin(['assets'], {
    root: __dirname, verbose: true, dry: false
  }));
}

module.exports = {
  entry: entries,
  output: {
    path: path.resolve('./public/assets'),
    filename: `${fileName}.js`,
    publicPath: publicPath
  },
  devtool: devtool,
  plugins: plugins,
  module: {
    loaders: [
      {
        test: /\.jsx?$/,
        exclude: /node_modules/,
        loader: 'babel'
      },
      {
        test: /\.css$/,
        loader: ExtractTextPlugin.extract('style-loader', 'css-loader')
      },
      {
        test: /\.scss$/,
        loader: ExtractTextPlugin.extract('style-loader', 'css-loader!sass-loader')
      },
      {
        test: /\.sass$/,
        loader: ExtractTextPlugin.extract('style-loader', 'css-loader!sass-loader')
      },
      {
        test: /\.svg(\?v=\d+\.\d+\.\d+)?$/,
        loader: 'url-loader?mimetype=image/svg+xml'
      },
      {
        test: /\.woff(\d+)?(\?v=\d+\.\d+\.\d+)?$/,
        loader: 'url-loader?mimetype=application/font-woff'
      },
      {
        test: /\.eot(\?v=\d+\.\d+\.\d+)?$/,
        loader: 'url-loader?mimetype=application/font-woff'
      },
      {
        test: /\.ttf(\?v=\d+\.\d+\.\d+)?$/,
        loader: 'url-loader?mimetype=application/font-woff'
      },
      {
        test: /\.(jpg|png|gif)$/,
        loader: DEBUG ? 'file-loader?name=[name].[ext]' : 'file-loader?name=[name]-[hash].[ext]'
      }
    ]
  },
  resolve: {
    root: path.resolve('./app/frontend'),
    extensions: [ '', '.js', '.jsx', '.css', '.scss', '.sass' ]
  },
  devServer: {
    headers: {
      "Access-Control-Allow-Origin": "http://localhost:8081",
      "Access-Control-Allow-Credentials": "true"
    }
  }
};