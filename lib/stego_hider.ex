defmodule StegoHider do

  import Bitwise

  @moduledoc """
  Documentation for `StegoHider`.
  """




  @doc """
  Get a file's content by name.

  ## Examples

    iex> StegoHider.get_file("example.jpeg")
      {:ok, file_content, file_size}

    iex> StegoHider.get_file("noent.jpeg")
      {:error, :no_file_in_dir}
  """
  @spec get_file(file_name :: String.t()) :: tuple
  def get_file(file_name) do
    case File.read(file_name) do
      {:ok, file_content} ->
        file_size = get_file_size(file_name)
        {:ok, file_content, file_size}
      {:error, _reason} -> {:error, :no_file_in_dir}
    end
  end



  @doc """
  Get a file's size in bytes.

  ## Examples

    iex> StegoHider.get_file_size("example.jpeg")
      file_size

    iex> StegoHider.get_file_size("noent.jpeg")
      {:error, :no_file_size}
  """
  @spec get_file_size(file_name :: String.t()) :: integer # change to {:ok, float} | {:error, atom}
  def get_file_size(file_name) do
    with {:ok, file_info} <- File.stat(file_name) do
            file_info.size
    else
      _ -> {:error, :no_file_size}
    end
  end


  @doc """
  Gets the ratio of bytes between two files.

  ## Examples

    iex> StegoHider.get_ratio(1, 2)
      {:ok, 0.5}

    iex> StegoHider.get_ratio(1, 0)
      {:error, :infinity}
  """
  @spec get_ratio(num1 :: integer, num2 :: integer) :: {:ok, float} | {:error, atom}
  def get_ratio(_, 0), do: {:error, :infinity}

  @spec get_ratio(num1 :: integer, num2 :: integer) :: float
  def get_ratio(cover_file_size, secret_file_size) do
    {:ok, ratio} = {:ok, cover_file_size / secret_file_size}
  end

  @doc """
  Changes the last bit of a byte.

  ## Examples

    iex> StegoHider.get_ratio(1, 240)
      {:ok, 241}

    iex> StegoHider.get_ratio(1, 241)
      {:ok, 241}

    iex> StegoHider.get_ratio(0, 241)
      {:ok, 240}

  """
  @spec change_last_bit(sec_bit :: integer, cover_byte :: bitstring) :: {:ok, integer}
  def change_last_bit(sec_bit, <<cover_byte::size(8)>>) do
    cover_last_bit = cover_byte &&& 1

    if (sec_bit !== cover_last_bit) do
      new_cover_byte = cover_byte &&& 254 ||| sec_bit
      {:ok, new_cover_byte}
    else
      {:ok, cover_byte}
    end
  end

  def create_stego_file(secret_file_name, cover_file_name) do
    with {:ok, secret_bitstring, secret_size} <- get_file(secret_file_name),
        {:ok, cover_bitstring, cover_size} <- get_file(cover_file_name),
        {:ok, ratio} <- get_ratio(cover_size, secret_size) do
      ratio = ceil(ratio)

      cover_as_list = :binary.bin_to_list(cover_bitstring)
      cover_chunks = Enum.chunk_every(cover_as_list, ratio)
      elements = Enum.map(cover_chunks, &hd/1)

      List.last(elements)
    end
  end

end
