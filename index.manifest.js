import indexTemplate from 'html-webpack-template-pug';

export const index = {
  inject: false,
  template: indexTemplate,
  mobile: true,
  title: 'Space Invaders',
  injectExtras: {
    head: [
      {
        tag: 'link',
        rel: 'shortcut icon',
        href: 'images/favicon.png',
        type: 'image/x-icon'
      },
      {
        tag: 'base',
        href: '/'
      },
      {
        tag: 'meta',
        name: 'description',
        content: 'n/a'
      },
      {
        tag: 'meta',
        name: 'version',
        content: '0.1.0'
      }
    ],
    body: [
      {tag: 'app'},
      {
        tag: 'script',
        async: '',
        src: 'https://www.googletagmanager.com/gtag/js?id=UA-49864967-4'
      },
      {
        tag: 'script',
        innerHTML: `
          window.dataLayer = window.dataLayer || [];
          function gtag(){dataLayer.push(arguments);}
          gtag('js', new Date());
          gtag('config', 'UA-49864967-4');
        `
      },
      {
        tag: 'noscript',
        innerHTML: "JavaScript is disabled in your browser."+
          "<a href='http://www.enable-javascript.com/' target='_blank'>"+
          "Here</a> is how to enable it."
      }
    ]
  }
}
