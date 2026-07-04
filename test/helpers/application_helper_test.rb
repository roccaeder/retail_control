require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  # url_for en el helper necesita contexto de ruta.
  # Lo sobreescribimos para devolver URLs predecibles sin depender del router.
  def url_for(options = {})
    return options if options.is_a?(String)
    "/?page=#{options[:page]}"
  end

  FakePagy = Struct.new(:previous, :next, :page, :pages, keyword_init: true)

  def make_pagy(previous: nil, nxt: nil, page: 1, pages: 1)
    FakePagy.new(previous: previous, next: nxt, page: page, pages: pages)
  end

  # ── pagy.previous ─────────────────────────────────────────────────────────
  describe "previous page" do
    test "renders a link when previous page exists" do
      html = pagy_tailwind_nav(make_pagy(previous: 1, page: 2, pages: 2))
      assert_includes html, 'href="/?page=1"'
      assert_includes html, "←"
    end

    test "renders a disabled span when no previous page" do
      html = pagy_tailwind_nav(make_pagy(previous: nil, page: 1, pages: 1))
      assert_includes html, "cursor-default"
      assert_includes html, "←"
      assert_not_includes html, 'href="/?page="'
    end
  end

  # ── pagy.next ─────────────────────────────────────────────────────────────
  describe "next page" do
    test "renders a link when next page exists" do
      html = pagy_tailwind_nav(make_pagy(nxt: 3, page: 2, pages: 3))
      assert_includes html, 'href="/?page=3"'
      assert_includes html, "→"
    end

    test "renders a disabled span when no next page" do
      html = pagy_tailwind_nav(make_pagy(nxt: nil, page: 1, pages: 1))
      assert_includes html, "cursor-default"
      assert_includes html, "→"
    end
  end

  # ── page numbers ──────────────────────────────────────────────────────────
  describe "page numbers" do
    test "renders every page from 1 to pages as a link" do
      html = pagy_tailwind_nav(make_pagy(page: 2, pages: 3))
      assert_includes html, 'href="/?page=1"'
      assert_includes html, 'href="/?page=3"'
    end

    test "renders the current page as a highlighted span, not a link" do
      html = pagy_tailwind_nav(make_pagy(page: 2, pages: 3))
      assert_includes html, "bg-stone-900"
      assert_includes html, ">2<"
      assert_not_includes html, 'href="/?page=2"'
    end
  end
end
