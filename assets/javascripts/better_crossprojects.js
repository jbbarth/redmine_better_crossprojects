/*
Effect.BlindRight = function(element) {
  element = $(element);
  var elementDimensions = element.getDimensions();
  return new Effect.Scale(element, 100, Object.extend({
    scaleContent: false,
    scaleY: false,
    scaleFrom: 0,
    scaleMode: {originalHeight: elementDimensions.height, originalWidth: elementDimensions.width},
    restoreAfterFinish: true,
    afterSetup: function(effect) {
      effect.element.makeClipping().setStyle({
        width: '0px',
        height: effect.dims[0] + 'px'
      }).show();
    },
    afterFinishInternal: function(effect) {
      effect.element.undoClipping();
    }
  }, arguments[1] || { }));
};

Effect.BlindLeft = function(element) {
  element = $(element);
  element.makeClipping();
  return new Effect.Scale(element, 0, Object.extend({
    scaleContent: false,
    scaleY: false,
    scaleMode: 'box',
    restoreAfterFinish: true,
    afterSetup: function(effect) {
      effect.element.makeClipping().setStyle({
        height: effect.dims[0] + 'px'
      }).show();
    },
    afterFinishInternal: function(effect) {
      effect.element.hide().undoClipping();
    }
  }, arguments[1] || { }));
};
*/

//draw activity sparklines on projects/index page
$(function() {
  $(".barchart").peity("bar", { colours: ["#aaa"], min: 0, max: 10,
                                height:18, width: (52/2*(5+1)-1) });
})
