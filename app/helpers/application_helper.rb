module ApplicationHelper

  def pagy_tailwind_nav(pagy)
    html = +'<nav class="flex items-center gap-1">'

    if pagy.previous
      html << link_to("←", url_for(page: pagy.previous), class: "px-3 py-1.5 text-sm rounded-lg border border-stone-200 text-stone-600 hover:bg-stone-50 transition-colors")
    else
      html << '<span class="px-3 py-1.5 text-sm rounded-lg border border-stone-100 text-stone-300 cursor-default">←</span>'
    end

    (1..pagy.pages).each do |page_num|
      if page_num == pagy.page
        html << %(<span class="px-3 py-1.5 text-sm rounded-lg bg-stone-900 text-white cursor-default">#{page_num}</span>)
      else
        html << link_to(page_num, url_for(page: page_num), class: "px-3 py-1.5 text-sm rounded-lg border border-stone-200 text-stone-600 hover:bg-stone-50 transition-colors")
      end
    end

    if pagy.next
      html << link_to("→", url_for(page: pagy.next), class: "px-3 py-1.5 text-sm rounded-lg border border-stone-200 text-stone-600 hover:bg-stone-50 transition-colors")
    else
      html << '<span class="px-3 py-1.5 text-sm rounded-lg border border-stone-100 text-stone-300 cursor-default">→</span>'
    end

    html << "</nav>"
    html.html_safe
  end
end
