defmodule Mrgr.DateTime do
  @q1 [1, 2, 3]
  @q2 [4, 5, 6]
  @q3 [7, 8, 9]
  @q4 [10, 11, 12]

  # false if they're the same time
  def before?(dt1, dt2) do
    case DateTime.compare(dt1, dt2) do
      :lt -> true
      _ -> false
    end
  end

  # false if they're the same time
  def after?(dt1, dt2) do
    case DateTime.compare(dt1, dt2) do
      :gt -> true
      _ -> false
    end
  end

  def in_the_past?(dt) do
    before?(dt, now())
  end

  def in_the_future?(dt) do
    after?(dt, now())
  end

  def future?(dt) do
    dt
    |> DateTime.compare(now())
    |> case do
      :gt -> true
      _ -> false
    end
  end

  def now do
    DateTime.utc_now()
  end

  def elapsed(starting, unit \\ :millisecond) do
    DateTime.diff(now(), starting, unit)
  end

  def safe_truncate(nil), do: nil

  def safe_truncate(dt) do
    DateTime.truncate(dt, :second)
  end

  def shift_from_now(amount, unit \\ :second) do
    now()
    |> DateTime.add(amount, unit)
    |> safe_truncate()
  end

  def beginning_of_year(year) do
    DateTime.new!(Date.new!(year, 1, 1), ~T[00:00:00.000], "Etc/UTC")
  end

  def end_of_year(year) do
    # 12:59:59pm
    DateTime.new!(Date.new!(year + 1, 1, 1), ~T[00:00:00.000], "Etc/UTC")
    |> DateTime.add(-1)
  end

  def previous_month(%Date{day: day} = date) do
    days = max(day, Date.add(date, -day).day)
    Date.add(date, -days)
  end

  def previous_month(%DateTime{day: day} = date) do
    days = max(day, DateTime.add(date, -day, :day).day)
    DateTime.add(date, -days, :day)
  end

  def previous_quarter(datetime) do
    Enum.reduce(1..3, datetime, fn _, acc -> previous_month(acc) end)
  end

  def end_of_quarter(datetime) do
    month =
      datetime
      |> get_quarter
      |> Enum.max()

    date = Date.new!(datetime.year, month, 1) |> Date.end_of_month()

    DateTime.new!(date, ~T[23:59:59.999])
  end

  def beginning_of_quarter(datetime) do
    month =
      datetime
      |> get_quarter
      |> Enum.min()

    %{datetime | month: month, day: 1, hour: 00, minute: 00, second: 00}
  end

  # returns the array! not a quarter name
  defp get_quarter(datetime) do
    case datetime.month do
      q1 when q1 in @q1 -> @q1
      q2 when q2 in @q2 -> @q2
      q3 when q3 in @q3 -> @q3
      q4 when q4 in @q4 -> @q4
    end
  end

  ### PROTOCOL ALERT ###
  def happened_at(%Mrgr.Schema.Comment{} = comment) do
    comment.posted_at
  end

  def happened_at(%Mrgr.Github.Commit{} = commit) do
    commit.author.date
  end
end
