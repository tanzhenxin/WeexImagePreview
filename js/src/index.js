

const WeexPlguinDemo = {
  show() {
    console.log('module WeexPlguinDemo is created sucessfully');
      alert("module WeexPlguinDemo is created sucessfully ")
  }
};


var meta = {
   WeexPlguinDemo: [{
    name: 'show',
    args: []
  }]
};



if(window.Vue) {
  weex.registerModule('weexPlguinDemo', WeexPlguinDemo);
}

function init(weex) {
  weex.registerApiModule('weexPlguinDemo', WeexPlguinDemo, meta);
}
module.exports = {
  init:init
};
