var path              = require( 'path' );
var webpack           = require( 'webpack' );
var merge             = require( 'webpack-merge' );
var autoprefixer      = require( 'autoprefixer' );
var ExtractTextPlugin = require( 'extract-text-webpack-plugin' );
var CopyWebpackPlugin = require( 'copy-webpack-plugin' );

console.log( 'WEBPACK GO!');

// detemine build env
var TARGET_ENV = process.env.npm_lifecycle_event === 'build' ? 'production' : 'development';

// common webpack config
var commonConfig = {

  output: {
    path:       path.resolve( __dirname, 'priv/static/' ),
    filename: 'js/[name].js',
  },

  entry: {
    google_login: [
      path.join(__dirname, 'web/static/js/google_login.js')
    ],
    sms_login: [
      path.join(__dirname, 'web/static/js/sms_login.js')
    ],
    user_permissions: [
      path.join(__dirname, 'web/static/js/user_permissions.js')
    ],
    permissions: [
      path.join(__dirname, 'web/static/js/permissions.js')
    ],
    cache_edit: [
      path.join(__dirname, 'web/static/js/cache_edit.js')
    ],
    data_source_edit: [
      path.join(__dirname, 'web/static/js/data_source_edit.js')
    ],
    payment_check_edit: [
      path.join(__dirname, 'web/static/js/payment_check_edit.js')
    ],
    dashboard: [
      path.join( __dirname, 'web/static/js/canvasjs.min.js')
    ],
    highcharts: [
      'highstock-release/highstock.js',
    ],
    app: [
      "jquery/dist/jquery.min.js",
      "moment",
      "moment/locale/en-gb.js",
      "moment/locale/ru.js",
      'quill',
      'quill/dist/quill.snow.css',
      "tether/dist/js/tether.min.js",
      "bootstrap-v4-dev/scss/bootstrap.scss",
      "bootstrap-v4-dev/js/dist/alert.js",
      "bootstrap-v4-dev/js/dist/button.js",
      "bootstrap-v4-dev/js/dist/carousel.js",
      "bootstrap-v4-dev/js/dist/collapse.js",
      "bootstrap-v4-dev/js/dist/dropdown.js",
      "bootstrap-v4-dev/js/dist/modal.js",
      "bootstrap-v4-dev/js/dist/popover.js",
      "bootstrap-v4-dev/js/dist/scrollspy.js",
      "bootstrap-v4-dev/js/dist/tab.js",
      "bootstrap-v4-dev/js/dist/tooltip.js",
      "bootstrap-v4-dev/js/dist/util.js",
      'font-awesome/css/font-awesome.min.css',
      'selectize',
      'selectize/dist/css/selectize.bootstrap3.css',
      'eonasdan-bootstrap-datetimepicker/build/css/bootstrap-datetimepicker.min.css',
      'eonasdan-bootstrap-datetimepicker/build/js/bootstrap-datetimepicker.min.js',
      'accounting/accounting.min.js',
      path.join( __dirname, 'web/static/css/colors.css' ),
      path.join( __dirname, 'web/static/css/progress.css' ),
      path.join( __dirname, 'web/static/css/app.css' ),
      path.join( __dirname, 'web/static/js/app.js' ),
    ]
  },

  resolve: {
    modulesDirectories: ['node_modules'],
    extensions:         ['', '.js', '.elm'],
    alias: {
      'jquery': path.join(__dirname, 'node_modules/jquery'),
    }
  },

  module: {
    noParse: /\.elm$/,

    loaders: [
      {
          test: /highstock\.js$/,
          include: /node_modules/,
          loader: 'script'
      },
      {
          test: /accounting\.min\.js$/,
          include: /node_modules/,
          loader: 'script'
      },
      {
          test: /quill\.js$/,
          include: /node_modules/,
          loader: 'script'
      },
      {
        test: /\.(png|jpg)$/,
        loader: 'url-loader?limit=8192&name=/images/[hash].[ext]'
      },
      {
        test: /\.(woff|woff2)(\?v=\d+\.\d+\.\d+)?$/,
        loader: 'url?limit=10000&&name=/fonts/[hash].[ext]&mimetype=application/font-woff'
      },
      {
        test: /\.ttf(\?v=\d+\.\d+\.\d+)?$/,
        loader: 'url?limit=10000&name=/fonts/[hash].[ext]&mimetype=application/octet-stream'
      },
      {
        test: /\.eot(\?v=\d+\.\d+\.\d+)?$/,
        loader: 'file'
      },
      {
        test: /\.svg(\?v=\d+\.\d+\.\d+)?$/,
        loader: 'url?limit=10000&name=/fonts/[hash].[ext]&mimetype=image/svg+xml'
      },
      {
        test: /\.js$/,
        exclude: /(node_modules|bower_components)/,
        loader: 'babel',
        query: {
          presets: ['es2015']
        }
      },
      {
        test: require.resolve('jquery'),
        loader: 'expose?$!expose?jQuery'
      }
    ],
  },

  plugins: [
    new webpack.ProvidePlugin({
      $: "jquery",
      jQuery: "jquery",
      "window.jQuery": "jquery",
      Tether: "tether",
      "window.Tether": "tether",
      moment: "moment",
      Alert: "exports-loader?Alert!bootstrap-v4-dev/js/dist/alert",
      Button: "exports-loader?Button!bootstrap-v4-dev/js/dist/button",
      Carousel: "exports-loader?Carousel!bootstrap-v4-dev/js/dist/carousel",
      Collapse: "exports-loader?Collapse!bootstrap-v4-dev/js/dist/collapse",
      Dropdown: "exports-loader?Dropdown!bootstrap-v4-dev/js/dist/dropdown",
      Modal: "exports-loader?Modal!bootstrap-v4-dev/js/dist/modal",
      Popover: "exports-loader?Popover!bootstrap-v4-dev/js/dist/popover",
      Scrollspy: "exports-loader?Scrollspy!bootstrap-v4-dev/js/dist/scrollspy",
      Tab: "exports-loader?Tab!bootstrap-v4-dev/js/dist/tab",
      Tooltip: "exports-loader?Tooltip!bootstrap-v4-dev/js/dist/tooltip",
      Util: "exports-loader?Util!bootstrap-v4-dev/js/dist/util",
      accounting: "accounting"
    }),
  ],

  postcss: [ autoprefixer( { browsers: ['last 2 versions'] } ) ],

}

// additional webpack settings for local env (when invoked by 'npm start')
if ( TARGET_ENV === 'development' ) {
  console.log( 'Serving locally...');

  module.exports = merge( commonConfig, {

    devServer: {
      inline:   true,
      progress: true
    },

    plugins: [
      new ExtractTextPlugin("css/[name].css"),
      new CopyWebpackPlugin([
        {
          from: 'web/static/assets/',
          to:   'assets'
        },
      ]),
      new webpack.optimize.CommonsChunkPlugin("app", "js/app.js")
    ],

    module: {
      loaders: [
        {
          test:    /\.elm$/,
          exclude: [/elm-stuff/, /node_modules/],
          loader:  'elm-webpack?verbose=true&warn=true&debug=true'
        },
        {
          test: /\.css$/,
          loader: ExtractTextPlugin.extract('style', 'css-loader?root=images!postcss-loader')
        },
        {
          test: /\.scss$/,
          loader: ExtractTextPlugin.extract(
            "style",
            "css!sass?includePaths[]=" + __dirname + "/node_modules"
          )
        },
        {
          test: /\.less$/,
          loader: ExtractTextPlugin.extract(
            "style",
            "css!less?includePaths[]=" + __dirname + "/node_modules"
          )
        }
      ]
    }

  });
}

// additional webpack settings for prod env (when invoked via 'npm run build')
if ( TARGET_ENV === 'production' ) {
  console.log( 'Building for prod...');

  module.exports = merge( commonConfig, {

    module: {
      loaders: [
        {
          test:    /\.elm$/,
          exclude: [/elm-stuff/, /node_modules/],
          loader:  'elm-webpack?verbose=true'
        },
        {
          test: /\.css$/,
          loader: ExtractTextPlugin.extract('style', 'css-loader?root=images!postcss-loader')
        },
        {
          test: /\.scss$/,
          loader: ExtractTextPlugin.extract(
            "style",
            "css!sass?includePaths[]=" + __dirname + "/node_modules"
          )
        },
        {
          test: /\.less$/,
          loader: ExtractTextPlugin.extract(
            "style",
            "css!less?includePaths[]=" + __dirname + "/node_modules"
          )
        }

      ]
    },

    plugins: [
      new CopyWebpackPlugin([
        {
          from: 'web/static/assets/',
          to:   'assets'
        }
      ]),

      new webpack.optimize.CommonsChunkPlugin("app", "js/app.js"),
      new webpack.optimize.OccurenceOrderPlugin(),

      // extract CSS into a separate file
      new ExtractTextPlugin("css/[name].css"),
      //new ExtractTextPlugin( './[hash].css', { allChunks: true } ),

      // minify & mangle JS/CSS
      new webpack.optimize.UglifyJsPlugin({
          minimize:   true,
          compressor: { warnings: false },
          mangle:  true
      })
    ]

  });
}

