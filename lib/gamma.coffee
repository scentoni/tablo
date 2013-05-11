EPS = 1.0e-14
ASWITCH = 100
FPMIN = Number.MIN_VALUE

class @Gamma
  @lngamma: (xx) ->
    cof = [57.1562356658629235, -59.5979603554754912, 14.1360979747417471, -0.491913816097620199, .339946499848118887e-4, .465236289270485756e-4, -.983744753048795646e-4, .158088703224912494e-3, -.210264441724104883e-3, .217439618115212643e-3, -.164318106536763890e-3, .844182239838527433e-4, -.261908384015814087e-4, .368991826595316234e-5]
    throw "bad arg in lngamma"  if xx <= 0
    y = x = xx
    tmp = x + 5.24218750000000000 # 671/128
    tmp = (x + 0.5) * Math.log(tmp) - tmp
    ser = 0.999999999999997092
    for c in cof
      ser += c / ++y
    tmp + Math.log(2.5066282746310005 * ser / x)

  # Returns the incomplete gamma function P(a, x).
  @gammap: (a, x) ->
    if (x < 0.0 or a <= 0.0) then throw "bad args in gammap"
    if (x == 0.0)
      0.0
    else if (a >= ASWITCH)
      gammpapprox(a, x, 1) # quadrature
    else if (x < a + 1.0)
      gser(a, x) # series
    else
      1.0 - gcf(a, x) # continued fraction

  # Returns the incomplete gamma function Q(a, x) = 1 - P(a, x).
  @gammaq: (a, x) ->
    if (x < 0.0 or a <= 0.0) then throw "bad args in gammaq"
    if (x == 0.0)
      1.0
    else if (a >= ASWITCH)
      gammpapprox(a, x, 0) # quadrature
    else if (x < a + 1.0)
      1.0 - gser(a, x) # series
    else
      gcf(a, x) # continued fraction

# Returns the incomplete gamma function P(a, x) evaluated by its series representation.
gser = (a, x) ->
  gln = Gamma.lngamma(a)
  ap = a
  del = sum = 1.0 / a
  while true
    ++ap
    del *= x / ap
    sum += del
    if (Math.abs(del) < Math.abs(sum) * EPS)
      return sum*Math.exp(-x + a*Math.log(x) - gln)

# Returns the incomplete gamma function Q(a, x) evaluated by its continued fraction representation.
gcf = (a, x) ->
  gln = Gamma.lngamma(a)
  b = x + 1.0 - a
  c = 1.0 / FPMIN
  d = 1.0 / b
  h = d
  i = 1
  while true
    an = -i*(i-a)
    b += 2.0
    d = an*d + b
    if Math.abs(d) < FPMIN
      d = FPMIN
    c = b + an/c
    if Math.abs(c) < FPMIN
      c = FPMIN
    d = 1.0/d
    del = d*c
    h *= del
    if Math.abs(del-1.0) < EPS
      break
    ++i
  Math.exp(-x + a*Math.log(x) - gln)*h

gammpapprox = (a, x, psig) ->
  ngau = 18
  ngy = [0.0021695375159141994, 0.011413521097787704, 0.027972308950302116, 0.051727015600492421, 0.082502225484340941, 0.12007019910960293, 0.16415283300752470, 0.21442376986779355, 0.27051082840644336, 0.33199876341447887, 0.39843234186401943, 0.46931971407375483, 0.54413605556657973, 0.62232745288031077, 0.70331500465597174, 0.78649910768313447, 0.87126389619061517, 0.95698180152629142]
  ngw = [0.0055657196642445571, 0.012915947284065419, 0.020181515297735382, 0.027298621498568734, 0.034213810770299537, 0.040875750923643261, 0.047235083490265582, 0.053244713977759692, 0.058860144245324798, 0.064039797355015485, 0.068745323835736408, 0.072941885005653087, 0.076598410645870640, 0.079687828912071670, 0.082187266704339706, 0.084078218979661945, 0.085346685739338721, 0.085983275670394821]
  a1 = a - 1.0
  lna1 = Math.log(a1)
  sqrta1 = Math.sqrt(a1)
  gln = Gamma.lngamma(a)
  if x > a1
    xu = Math.max(a1 + 11.5*sqrta1, x + 6.0*sqrta1)
  else
    xu = Math.max(0.0, Math.min(a1 - 7.5*sqrta1, x - 5.0*sqrta1))
  sum = 0.0
  for y, j in ngy
    t = x + (xu - x)*ngy[j]
    sum += ngw[j]*Math.exp(-(t - a1) + a1*(Math.log(t) - lna1))
  ans = sum*(xu - x)*Math.exp(a1*(lna1 - 1.0) - gln)
  if psig # return P(a, x)
    if ans>0.0
      1.0 - ans
    else
      -ans
  else # return Q(a, x)
    if ans>=0.0
      ans
    else
      1.0 + ans

# 281/1262

# assertapprox("Gamma.lngamma(2.3)", 0.154189454959630581)
# assertapprox("gammpapprox(200.0, 237.5, 0)", 0.005781566523417125)
# assertapprox("gammpapprox(200.0, 237.5, 1)", 1 - 0.005781566523417125)
# assertapprox("gser(1.0, 1.5)", 1 - 0.223130160148429828)
# assertapprox("gcf(1.0, 1.5)", 0.223130160148429828)
