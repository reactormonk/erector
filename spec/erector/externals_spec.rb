require File.expand_path("#{File.dirname(__FILE__)}/../spec_helper")

describe Erector::Externals do
  class Dinner < Erector::Widget
    external :js, "/dinner.js"
    def content
      span "dinner"
      widget Dessert
    end
  end

  class Dessert < Erector::Widget
    external :js, "/dessert.js"
    external :css, "/dessert.css"
    def content
      span "dessert"
    end
  end

  it "#render_with_externals sticks the externals for all its rendered sub-widgets at the end of the output buffer" do
    s = Dinner.new.render_with_externals
    s.join.should ==
      "<span>dinner</span>" +
      "<span>dessert</span>" +
      "<link href=\"/dessert.css\" media=\"all\" rel=\"stylesheet\" type=\"text/css\" />" +
      "<script src=\"/dinner.js\" type=\"text/javascript\"></script>" +
      "<script src=\"/dessert.js\" type=\"text/javascript\"></script>"
  end

  it "#render_externals returns externals for all rendered sub-widgets to an output buffer" do
    widget = Dinner.new
    widget.to_s
    widget.render_externals.join.should ==
      "<link href=\"/dessert.css\" media=\"all\" rel=\"stylesheet\" type=\"text/css\" />" +
      "<script src=\"/dinner.js\" type=\"text/javascript\"></script>" +
      "<script src=\"/dessert.js\" type=\"text/javascript\"></script>"
  end
end
