function array_find(arr, f)
  for a in all(arr) do
    if f(a) then
      return a
    end
  end
end