# http://stackoverflow.com/questions/15831144/global-classes-with-meteor-0-6-0-and-coffeescript
class @Chisq
  @cdf: (df, x2) ->
      if df < 0 then throw "bad df in Chisq.cdf"
      if x2 < 0.0 then throw "bad x2 in Chisq.cdf"
      # fac = Math.LN2*(0.5*df) + gammln(0.5*df)
      Gamma.gammap(0.5*df, 0.5*x2)

  @pvalue: (df, x2) ->
      if df < 0 then throw "bad df in Chisq.cdf"
      if x2 < 0.0 then throw "bad x2 in Chisq.cdf"
      # fac = Math.LN2*(0.5*df) + gammln(0.5*df)
      Gamma.gammaq(0.5*df, 0.5*x2)

# assertapprox = (expression, expected, eps = 1.0e-14) ->
#   actual = eval(expression)
#   if Math.abs(actual - expected) <= eps
#     verdict = "correct"
#   else
#     verdict = "INCORRECT! SHOULD BE " + expected
#   console.log expression + " = " + actual + ": " + verdict

# assertapprox("Chisq.cdf(6, 12.3)", 1 - 0.055601201779395237)
# assertapprox("Gamma.gammaq(200.0, 237.5)", 0.005781566523417125)
# assertapprox("Gamma.gammap(200.0, 237.5)", 1 - 0.005781566523417125)
# assertapprox("Gamma.gammap(1.0, 1.5)", 1 - 0.223130160148429828)
