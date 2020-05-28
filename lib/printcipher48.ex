defmodule Printcipher48 do
  use Bitwise

  @substitution %{
    [0, 0, 0] => [0, 0, 0],
    [0, 0, 1] => [0, 0, 1],
    [0, 1, 0] => [0, 1, 1],
    [0, 1, 1] => [1, 1, 0],
    [1, 0, 0] => [1, 1, 1],
    [1, 0, 1] => [1, 0, 0],
    [1, 1, 0] => [1, 0, 1],
    [1, 1, 1] => [0, 1, 0]
  }

  @reverse_substitution %{
    [0, 0, 0] => [0, 0, 0],
    [0, 0, 1] => [0, 0, 1],
    [0, 1, 1] => [0, 1, 0],
    [1, 1, 0] => [0, 1, 1],
    [1, 1, 1] => [1, 0, 0],
    [1, 0, 0] => [1, 0, 1],
    [1, 0, 1] => [1, 1, 0],
    [0, 1, 0] => [1, 1, 1]
  }

  def encrypt(plaintext, key, permkey) do
    counter = [0, 0, 0, 0, 0, 0]

    {cyphertext, _counter} =
      Enum.reduce(0..47, {plaintext, counter}, fn _step, {plaintext, counter} ->
        cyphertext =
          plaintext
          |> xor(key)
          |> bytes_to_bits_array()
          |> linear_diffusion()

        {cyphertext, counter} = round_counter(cyphertext, counter)

        cyphertext =
          cyphertext
          |> permutation(permkey)
          |> bits_array_to_binary()

        {cyphertext, counter}
      end)

    cyphertext
  end

  def decrypt(cyphertext, key, permkey) do
    counter = [1, 0, 0, 1, 0, 0]

    {plaintext, _counter} =
      Enum.reduce(0..47, {cyphertext, counter}, fn _step, {cyphertext, counter} ->
        cyphertext =
          cyphertext
          |> bytes_to_bits_array()
          |> reverse_permutation(permkey)

        {cyphertext, counter} = reverse_round_counter(cyphertext, counter)

        cyphertext =
          cyphertext
          |> reverse_linear_diffusion()
          |> bits_array_to_binary()
          |> xor(key)

        {cyphertext, counter}
      end)

    plaintext
  end

  defp xor(text, key) do
    :crypto.exor(text, key)
  end


  defp linear_diffusion(bits_array) do
    result = List.duplicate(nil, 48)

    bits_array
    |> Enum.with_index()
    |> Enum.reduce(result, fn {bit, from}, result ->
      if from != 47 do
        to = rem(from * 3, 47)
        List.update_at(result, to, fn _ -> bit end)
      else
        List.update_at(result, 47, fn _ -> bit end)
      end
    end)
  end

  defp reverse_linear_diffusion(bits_array) do
    bits_array
    |> Enum.with_index()
    |> Enum.map(fn {bit, index} ->
      if index != 47 do
        Enum.at(bits_array, rem(index * 3, 47))
      else
        bit
      end
    end)
  end


  defp round_counter(bits_array, counter) do
    counter = next_round_counter(counter)
    result = xor_counter(bits_array, counter)
    {result, counter}
  end

  def next_round_counter(counter) do
    t = rem(1 + Enum.at(counter, 5) + Enum.at(counter, 4), 2)
    counter = Enum.slice(counter, 0..4)
    [t] ++ counter
  end

  defp reverse_round_counter(bits_array, counter) do
    counter = reverse_next_round_counter(counter)
    result = xor_counter(bits_array, counter)
    {result, counter}
  end

  def reverse_next_round_counter(counter) do
    t = rem(1 + Enum.at(counter, 0) + Enum.at(counter, 5), 2)
    counter = Enum.slice(counter, 1..5)
    counter ++ [t]
  end

  defp xor_counter(bits_array, counter) do
    Enum.reduce(42..47, bits_array, fn index, bits_array ->
      counter_bit = Enum.at(counter, 47 - index)
      List.update_at(bits_array, index, fn bit -> counter_bit ^^^ bit end)
    end)
  end


  defp permutation(bits_array, permkey) do
    permute(bits_array, bytes_to_bits_array(permkey), [])
  end

  defp permute([b0, b1, b2 | tail], [permkey_bit0, permkey_bit1 | permkey_tail], result) do
    permuted =
      case {permkey_bit0, permkey_bit1} do
        {0, 0} -> substitute([b0, b1, b2])
        {0, 1} -> substitute([b1, b0, b2])
        {1, 0} -> substitute([b0, b2, b1])
        {1, 1} -> substitute([b2, b1, b0])
      end

    permute(tail, permkey_tail, result ++ permuted)
  end

  defp permute([], _, result), do: result

  defp substitute(from), do: @substitution[from]

  defp reverse_permutation(bits_array, permkey) do
    reverse_permute(bits_array, bytes_to_bits_array(permkey), [])
  end

  defp reverse_permute([b0, b1, b2 | tail], [permkey_bit0, permkey_bit1 | permkey_tail], result) do
    [b0, b1, b2] = reverse_substitute([b0, b1, b2])

    permuted =
      case {permkey_bit0, permkey_bit1} do
        {0, 0} -> [b0, b1, b2]
        {0, 1} -> [b1, b0, b2]
        {1, 0} -> [b0, b2, b1]
        {1, 1} -> [b2, b1, b0]
      end

    reverse_permute(tail, permkey_tail, result ++ permuted)
  end

  defp reverse_permute([], _, result), do: result

  defp reverse_substitute(from), do: @reverse_substitution[from]

  defp byte_to_bits_array(i) do
    <<b8::size(1), b7::size(1), b6::size(1), b5::size(1), b4::size(1), b3::size(1), b2::size(1),
      b1::size(1)>> = i

    [b8, b7, b6, b5, b4, b3, b2, b1]
  end

  defp bytes_to_bits_array(bytes), do: _bytes_to_bits_array(bytes, [])

  defp _bytes_to_bits_array(<<byte::binary-size(1), rest::binary>>, bits_array) do
    bits = byte_to_bits_array(byte)
    _bytes_to_bits_array(rest, bits_array ++ bits)
  end

  defp _bytes_to_bits_array(<<>>, bits_array) do
    bits_array
  end

  defp bits_array_to_binary(array) do
    Enum.into(array, <<>>, fn bit -> <<bit::1>> end)
  end
end

