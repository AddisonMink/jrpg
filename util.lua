function array_find(arr, f)
  for a in all(arr) do
    if f(a) then
      return a
    end
  end
end

function copy_table(t)
  local t2 = {}
  for k, v in pairs(t) do
    t2[k] = v
  end
  return t2
end