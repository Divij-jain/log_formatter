defmodule LogFormatter do
  def format(level, message, {date, time}, metadata) do
    add_data(level, message, {date, time}, metadata)
    |> Jason.encode_to_iodata!()
    |> newline_delimit()
  end

  def add_data(level, message, {date, time}, metadata) do
    %{
      level: level,
      message: message |> IO.chardata_to_string(),
      timestamp: add_datetime(date, time)
    }
    |> Map.merge(add_metadata(metadata))
  end

  defp add_datetime(date, time) do
    date = Logger.Formatter.format_date(date)
    time = Logger.Formatter.format_time(time)
    [date, ?T, time, ?Z] |> IO.chardata_to_string()
  end

  defp add_metadata(metadata) do
    format_metadata(metadata)
  end

  defp newline_delimit(log) do
    [log | "\n"]
  end

  defp format_metadata([]), do: %{}

  defp format_metadata([{_key, _data} | _] = metadata) do
    Enum.into(metadata, %{}, fn {key, data} ->
      {key, format_metadata(data)}
    end)
  end

  defp format_metadata(%Jason.Fragment{} = data) do
    data
  end

  defp format_metadata(nil), do: nil
  defp format_metadata(true), do: true
  defp format_metadata(false), do: false

  defp format_metadata(data) when is_atom(data) do
    Atom.to_string(data)
  end

  defp format_metadata(%DateTime{} = data) do
    DateTime.to_string(data)
  end

  defp format_metadata(%NaiveDateTime{} = data) do
    NaiveDateTime.to_string(data)
  end

  defp format_metadata(%_struct{} = data) do
    if jason_implemented?(data) do
      data
    else
      Map.from_struct(data)
      |> format_metadata()
    end
  end

  defp format_metadata(%{} = data) do
    for({key, value} <- data, into: %{}, do: {key, format_metadata(value)})
  end

  defp format_metadata(data) when is_number(data) do
    data
  end

  defp format_metadata(data) when is_binary(data) do
    data
  end

  defp format_metadata(data) when is_tuple(data) do
    Tuple.to_list(data)
    |> format_metadata()
  end

  defp format_metadata(data) when is_list(data) do
    for(d <- data, do: format_metadata(d))
  end

  defp format_metadata(data) do
    inspect(data)
  end

  defp jason_implemented?(data) do
    impl = Jason.Encoder.impl_for(data)
    impl && impl != Jason.Encoder.Any
  end
end
