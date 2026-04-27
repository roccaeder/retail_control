require "test_helper"

class ProductsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = create(:account)
    @user    = create(:user, account: @account)
    @product = create(:product, account: @account, name: "Coca Cola", sku: "SKU-001")
    sign_in @user
  end

  # ── Security ───────────────────────────────────────────────────────────────
  describe "security" do
    test "redirects to login when unauthenticated" do
      sign_out @user
      get products_path
      assert_redirected_to new_user_session_path
    end

    test "returns 404 for a product from another tenant" do
      other_account  = create(:account)
      other_product  = ActsAsTenant.with_tenant(other_account) { create(:product) }

      get product_path(other_product)
      assert_response :not_found
    end
  end

  # ── GET index ──────────────────────────────────────────────────────────────
  describe "GET #index" do
    test "responds 200" do
      get products_path
      assert_response :success
    end

    test "lists products belonging to the current account" do
      other_account = create(:account)
      ActsAsTenant.with_tenant(other_account) { create(:product, name: "Otro") }

      get products_path
      assert_select "td", text: /Coca Cola/
      assert_select "td", text: /Otro/, count: 0
    end
  end

  # ── GET show ───────────────────────────────────────────────────────────────
  describe "GET #show" do
    test "renders the product detail page" do
      get product_path(@product)
      assert_response :success
    end

    test "displays the product name" do
      get product_path(@product)
      assert_select "h1", text: /Coca Cola/
    end
  end

  # ── GET new ────────────────────────────────────────────────────────────────
  describe "GET #new" do
    test "renders the new product form" do
      get new_product_path
      assert_response :success
    end
  end

  # ── POST create ────────────────────────────────────────────────────────────
  describe "POST #create" do
    def valid_params(overrides = {})
      { product: { name: "Pepsi", sku: "SKU-002", cost_price: "1.00", sale_price: "1.50", stock: "20" }.merge(overrides) }
    end

    test "creates a product and redirects to index" do
      assert_difference "Product.count", 1 do
        post products_path, params: valid_params
      end
      assert_redirected_to products_path
      assert_match /creado correctamente/, flash[:notice]
    end

    test "assigns the product to the current account" do
      post products_path, params: valid_params
      assert_equal @account, Product.last.account
    end

    test "returns 422 when name is blank" do
      assert_no_difference "Product.count" do
        post products_path, params: valid_params(name: "")
      end
      assert_response :unprocessable_entity
    end

    test "returns 422 when sale_price is negative" do
      assert_no_difference "Product.count" do
        post products_path, params: valid_params(sale_price: "-1")
      end
      assert_response :unprocessable_entity
    end

    test "returns 422 when SKU is duplicated within the same account" do
      assert_no_difference "Product.count" do
        post products_path, params: valid_params(sku: "SKU-001")
      end
      assert_response :unprocessable_entity
    end

    test "allows the same SKU across different accounts" do
      sign_out @user
      other_account = create(:account)
      other_user    = create(:user, account: other_account)
      sign_in other_user

      assert_difference "Product.count", 1 do
        post products_path, params: valid_params(sku: "SKU-001")
      end
      assert_redirected_to products_path
    end
  end

  # ── GET edit ───────────────────────────────────────────────────────────────
  describe "GET #edit" do
    test "renders the edit form" do
      get edit_product_path(@product)
      assert_response :success
    end
  end

  # ── PATCH update ───────────────────────────────────────────────────────────
  describe "PATCH #update" do
    test "updates the product and redirects to index" do
      patch product_path(@product), params: { product: { name: "Coca Cola Zero" } }
      assert_redirected_to products_path
      assert_match /actualizado correctamente/, flash[:notice]
      assert_equal "Coca Cola Zero", @product.reload.name
    end

    test "returns 422 when name is blank" do
      patch product_path(@product), params: { product: { name: "" } }
      assert_response :unprocessable_entity
      assert_equal "Coca Cola", @product.reload.name
    end

    test "returns 422 when sale_price is negative" do
      patch product_path(@product), params: { product: { sale_price: "-5" } }
      assert_response :unprocessable_entity
    end
  end

  # ── DELETE destroy ─────────────────────────────────────────────────────────
  describe "DELETE #destroy" do
    test "deletes the product and redirects to index" do
      assert_difference "Product.count", -1 do
        delete product_path(@product)
      end
      assert_redirected_to products_path
      assert_match /eliminado correctamente/, flash[:notice]
    end

    test "does not delete a product that has associated sale items" do
      ActsAsTenant.with_tenant(@account) do
        create(:sale_item, product: @product, account: @account)
      end

      assert_no_difference "Product.count" do
        delete product_path(@product)
      end
      assert_redirected_to products_path
      assert flash[:alert].present?
    end
  end

  # ── GET search ─────────────────────────────────────────────────────────────
  describe "GET #search" do
    test "returns matching products by name" do
      get search_products_path, params: { q: "Coca" }
      assert_response :success
    end

    test "returns matching products by SKU" do
      get search_products_path, params: { q: @product.sku }
      assert_response :success
    end

    test "returns empty list when query is blank" do
      get search_products_path, params: { q: "" }
      assert_response :success
    end
  end
end
