/* Below, I compile all 3 Conference matrices into one long adjacency matrix, match everyone's full names, and collapse so each speaker appears only once. In the end, I get an edge list (edgelist.csv) with labels conducive for analysis in Gephi. */


// Import October 2026 Conference data
import delimited "$path/october2026.csv", emptylines(include) stringcols(1) clear

// Save to merge onto other conferences
tempfile oct26
save `oct26', replace

// Import April 2026 Conference data
import delimited "$path/april2026.csv", emptylines(include) stringcols(1) clear

// Append
append using `oct26'

tempfile octapr26
save `octapr26', replace

// Import October 2025 Conference data
import delimited "$path/october2025.csv", emptylines(include) stringcols(1) clear

// Append again
append using `octapr26'


// Now, I have all 3 appended into one long adjacency matrix. Make all missing ties 0
mvencode _all, mv(0) override

// Clean ID variable
replace id = strtrim(stritrim(id))
drop if id == ""

// Save variable labels (full names) to merge later on
ds id, not
local actors `r(varlist)'
local n : word count `actors'

local i 0
foreach v of local actors {
	local ++i
	local lab`i' : var lab `v'
	local lab`i' = strtrim(`"`lab`i''"')
	if `"`lab`i''"' == "" {
		local lab`i' "`v'"
	}
}

// Full name tempfile
preserve
	clear
	set obs `n'
	gen long j = _n
	gen str244 cited = ""
	forvalues i = 1/`n' {
		replace cited = `"`lab`i''"' in `i'
	}
	tempfile labels
	save `labels', replace
restore

// Rename columns to numbered stubs
local i 0
foreach v of local actors {
	local ++i
	rename `v' cc`i'
}

// Collapse so each speaker appears once while summing citations
foreach v of varlist cc* {
	replace `v' = 0 if missing(`v')
}
collapse (sum) cc*, by(id)
isid id

// Reshape long and attach full names
reshape long cc, i(id) j(j)
keep if cc > 0 & !missing(cc)

merge m:1 j using `labels', nogen keep(match)

// Change variable names so Gephi will read easily
rename id Source
rename cc Weight
rename cited Target
keep Source Weight Target
order Source Target Weight

// Export
export delimited using "$path/edgelist.csv", replace
