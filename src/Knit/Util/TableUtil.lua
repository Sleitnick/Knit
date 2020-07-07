local TableUtil = {}


function TableUtil.Extend(tbl, extension)
	for k,v in pairs(extension) do
		tbl[k] = v
	end
end


return TableUtil