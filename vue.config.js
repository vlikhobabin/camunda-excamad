module.exports = {
  publicPath: './',
  configureWebpack: {
    devtool: "source-map"
  },
  publicPath: process.env.NODE_ENV === "production" ? "/" : "/",
  devServer: {
    host: '0.0.0.0',
    port: 8080,
    allowedHosts: [
      'localhost',
      'excamad.eg-holding.ru',
      '.eg-holding.ru'
    ]
  },
  chainWebpack: config => {
    config.module
      .rule('yaml')
      .test(/\.ya?ml$/)
      .use('yaml-loader')
      .loader('yaml-loader')
      .end();
  }
};
