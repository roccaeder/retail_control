require "test_helper"

class Matching::NormalizerTest < ActiveSupport::TestCase
  test "colapsa mayúsculas, guiones y espacios repetidos" do
    assert_equal "coca cola 500ml", Matching::Normalizer.call("  Coca Cola   500ML ")
    assert_equal "coca cola 500ml", Matching::Normalizer.call("COCA-COLA 500 ml")
  end

  test "unifica variantes de unidades a una forma canónica" do
    assert_equal "leche gloria 400g", Matching::Normalizer.call("Leche Gloria 400grs")
    assert_equal "leche gloria 400g", Matching::Normalizer.call("Leche Gloria 400 GR")
    assert_equal "aceite primor 1l", Matching::Normalizer.call("Aceite Primor 1 Lt")
    assert_equal "aceite primor 1l", Matching::Normalizer.call("Aceite Primor 1 Litro")
    assert_equal "gaseosa 500ml", Matching::Normalizer.call("Gaseosa 500cc")
    assert_equal "yogurt 1kg", Matching::Normalizer.call("Yogurt 1 Kilo")
    assert_equal "pack x6un", Matching::Normalizer.call("Pack x6 Unidades")
  end

  test "preserva decimales al normalizar unidades" do
    assert_equal "inca kola 1.5l", Matching::Normalizer.call("Inca Kola 1.5L")
    assert_equal "inca kola 1.5l", Matching::Normalizer.call("Inca Kola 1,5L")
  end

  test "elimina tildes y eñes conservando el sonido" do
    assert_equal "papel higienico suave", Matching::Normalizer.call("Papel Higiénico Suave")
    assert_equal "arroz costeno extra 750g", Matching::Normalizer.call("Arroz Costeño Extra 750Grs")
  end

  test "elimina puntuación que no forma parte de un número" do
    assert_equal "detergente ariel 850g", Matching::Normalizer.call("Detergente Ariel 850 g.")
    assert_equal "distribuidora s a c", Matching::Normalizer.call("Distribuidora S.A.C.")
  end

  test "entrada en blanco o nil normaliza a cadena vacía" do
    assert_equal "", Matching::Normalizer.call("")
    assert_equal "", Matching::Normalizer.call("   ")
    assert_equal "", Matching::Normalizer.call(nil)
  end

  test "no altera texto ya normalizado" do
    assert_equal "coca cola 500ml", Matching::Normalizer.call("coca cola 500ml")
  end
end
