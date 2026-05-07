require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  # url_for en el helper necesita contexto de ruta.
  # Lo sobreescribimos para devolver URLs predecibles sin depender del router.
  def url_for(options = {})
    return options if options.is_a?(String)
    "/?page=#{options[:page]}"
  end

  FakePagy = Struct.new(:prev, :next, :series, keyword_init: true)

  def make_pagy(prev: nil, nxt: nil, series: ["1"])
    FakePagy.new(prev: prev, next: nxt, series: series)
  end

  # ── pagy.prev ─────────────────────────────────────────────────────────────
  describe "previous page" do
    test "renders a link when prev page exists" do
      html = pagy_tailwind_nav(make_pagy(prev: 1, series: ["2"]))
      assert_includes html, 'href="/?page=1"'
      assert_includes html, "←"
    end

    test "renders a disabled span when no prev page" do
      html = pagy_tailwind_nav(make_pagy(prev: nil, series: ["1"]))
      assert_includes html, "cursor-default"
      assert_includes html, "←"
      assert_not_includes html, 'href="/?page="'
    end
  end

  # ── pagy.next ─────────────────────────────────────────────────────────────
  describe "next page" do
    test "renders a link when next page exists" do
      html = pagy_tailwind_nav(make_pagy(nxt: 3, series: ["2"]))
      assert_includes html, 'href="/?page=3"'
      assert_includes html, "→"
    end

    test "renders a disabled span when no next page" do
      html = pagy_tailwind_nav(make_pagy(nxt: nil, series: ["1"]))
      assert_includes html, "cursor-default"
      assert_includes html, "→"
    end
  end

  # ── pagy.series ───────────────────────────────────────────────────────────
  describe "series items" do
    test "renders Integer pages as links" do
      html = pagy_tailwind_nav(make_pagy(series: [1, "2", 3]))
      assert_includes html, 'href="/?page=1"'
      assert_includes html, 'href="/?page=3"'
    end

    test "renders String (current page) as highlighted span" do
      html = pagy_tailwind_nav(make_pagy(series: [1, "2", 3]))
      assert_includes html, "bg-stone-900"
      assert_includes html, ">2<"
    end

    test "renders :gap as ellipsis" do
      html = pagy_tailwind_nav(make_pagy(series: [1, :gap, 5]))
      assert_includes html, "…"
    end

    test "ignores unknown series item types" do
      html = pagy_tailwind_nav(make_pagy(series: [:unknown]))
      assert_not_includes html, "href"
    end
  end
end
