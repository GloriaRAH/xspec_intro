# This script create a binned dataset which is more compatible with XSPEC
using CSV
using DataFrames

# Read in data values
# Input data: ν [Hz], νF_ν [erg/cm^2/s]
file = CSV.File(@__DIR__() * "/../data/dataset-input.csv"; comment="#")

#= Changing units to keV and counts in bin 
See unit conversion tables in Zombeck, Handbook of Space Astronomy and Astrophysics 
[../docs/Flux-Conversion-Zombeck.pdf]
ν; Hz -> keV; bin width ±5% of bin centre
νF_ν; erg/cm^2/s -> photons/cm^2/s in bin; ±10% errors =#

# Prepare the histogram of "energies" - note that these bins are not contiguous
E = 4.14E-18 * file.nu[1:25]

# Generate an "error range" for the bins - note that this is arbitrary at the moment!
E_low = 4.14E-18 * file.nu[1:25] .* 0.95
E_high = 4.14E-18 * file.nu[1:25] .* 1.05
ΔE = E_high .- E_low

# Prepare the histogram of "counts"
νF_ν = file.nuFnu[1:25]
F_ν = νF_ν ./ file.nu[1:25]
f_E = 1.51E26 .* F_ν ./ E

# XSPEC wants quantities integrated over bin width
int_f_E = ΔE .* f_E

# Generate an "error range" - note that this is arbitrary at the moment!
int_f_E_err = 0.1 * int_f_E

# Create a CSV file that can be fed into `flx2xsp` (see https://heasarc.gsfc.nasa.gov/lheasoft/ftools/headas/flx2xsp.html)
# ftflx2xsp input binned data format: [low-energy, high-energy, flux, flux-error]
df = DataFrame(E_low=E_low, E_high=E_high, flux=int_f_E, flux_err=int_f_E_err)
CSV.write(@__DIR__() * "/../data/dataset-xspec.csv", df; delim=' ', writeheader=false)

println("Now you need to run the following in the data directory with HEASOFT initialised")
println("  ftflx2xsp dataset-xspec.csv dataset-xspec.pha dataset-xspec.rsp")
println("The output will use default units of keV and photons/cm^2/s")
