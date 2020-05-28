defmodule Printcipher48Test do
  use ExUnit.Case
  doctest Printcipher48

  test "Test encryption from the example" do
    key = Base.decode16!("C28895BA327B")
    permkey = Base.decode16!("69D2CDB6")
    plaintext = "4C847555C35B"

    cyphertext = plaintext
    |> Base.decode16!()
    |> Printcipher48.encrypt(key, permkey)
    |> Base.encode16()

    assert cyphertext == "EB4AF95E7D37"
  end

  test "Test decryption drom the exemple" do
    key = Base.decode16!("C28895BA327B")
    permkey = Base.decode16!("69D2CDB6")
    cyphertext = "EB4AF95E7D37"

    plaintext = cyphertext
    |> Base.decode16!()
    |> Printcipher48.decrypt(key, permkey)
    |> Base.encode16()

    assert plaintext == "4C847555C35B"
  end

  test "Encrypt en decrypt data should return the same data" do
    key = :crypto.strong_rand_bytes(6)
    permkey = :crypto.strong_rand_bytes(4)
    plaintext = :crypto.strong_rand_bytes(6)

    assert plaintext
    |> Printcipher48.encrypt(key, permkey)
    |> Printcipher48.decrypt(key, permkey)
    == plaintext
  end

end
