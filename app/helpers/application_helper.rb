module ApplicationHelper
  def page_title(title = nil)
    if title
      @page_title = title
    else
      @page_title
    end
  end
end
