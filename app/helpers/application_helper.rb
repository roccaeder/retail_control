module ApplicationHelper
  include Pagy::Frontend

  def pagy_tailwind_nav(pagy)
    html = +'<nav class="flex items-center gap-1">'

    if pagy.prev
      html << link_to("←", url_for(page: pagy.prev), class: "px-3 py-1.5 text-sm rounded-lg border border-stone-200 text-stone-600 hover:bg-stone-50 transition-colors")
    else
      html << '<span class="px-3 py-1.5 text-sm rounded-lg border border-stone-100 text-stone-300 cursor-default">←</span>'
    end

    pagy.series.each do |item|
      case item
      when Integer
        html << link_to(item, url_for(page: item), class: "px-3 py-1.5 text-sm rounded-lg border border-stone-200 text-stone-600 hover:bg-stone-50 transition-colors")
      when String
        html << %(<span class="px-3 py-1.5 text-sm rounded-lg bg-stone-900 text-white">#{item}</span>)
      when :gap
        html << '<span class="px-2 py-1.5 text-sm text-stone-400">…</span>'
      end
    end

    if pagy.next
      html << link_to("→", url_for(page: pagy.next), class: "px-3 py-1.5 text-sm rounded-lg border border-stone-200 text-stone-600 hover:bg-stone-50 transition-colors")
    else
      html << '<span class="px-3 py-1.5 text-sm rounded-lg border border-stone-100 text-stone-300 cursor-default">→</span>'
    end

    html << '</nav>'
    html.html_safe
  end
end
