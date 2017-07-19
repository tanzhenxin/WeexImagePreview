import './index.css'
import VueImagePreview from './vue/image-preview.vue'

const WeexImagePreview = {
  show(params) {
    const node = document.createElement('div');
    node.className = 'weex-image-preview-mask';
    document.body.appendChild(node);

    const ImagePreview = Vue.extend(VueImagePreview);
    const vueImagePreviewInstance = new ImagePreview({
      el: node,
      data() {
        return params;
      }
    });
    vueImagePreviewInstance.$el.className = 'weex-image-preview-mask';
  }
};


var meta = {
   WeexImagePreview: [{
    name: 'show',
    args: []
  }]
};

if(window.Vue) {
  weex.registerModule('weexImagePreview', WeexImagePreview);
}

function init(weex) {
  weex.registerApiModule('weexImagePreview', WeexImagePreview, meta);
}
module.exports = {
  init:init
};
