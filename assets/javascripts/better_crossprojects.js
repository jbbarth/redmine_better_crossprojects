//draw activity sparklines on projects/index page
$(function() {
  $(".barchart").peity("bar", { colours: ["#aaa"], min: 0, max: 10,
                                height:18, width: (52/2*(5+1)-1) });
  $("table").on("click", ".more", function() {
    $(this).closest("tr").next().toggle()
  })
})
