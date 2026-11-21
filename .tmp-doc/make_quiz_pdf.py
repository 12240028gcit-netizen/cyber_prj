from pathlib import Path
import textwrap
OUT=Path('output/pdf/CSM202_Quiz_Lectures_08-11.pdf'); W,H=595,842
BLUE=(.08,.20,.32); GREY=(.34,.41,.47); ORANGE=(.91,.45,.12); pages=[]
def esc(s): return s.replace('\\','\\\\').replace('(','\\(').replace(')','\\)')
def col(c): return '%.3f %.3f %.3f'%c
def start(title,first=False):
 o=[f'{col(ORANGE)} rg','54 788 487 5 re f']; y=764
 if first:
  o += [f'BT /F2 21 Tf {col(BLUE)} rg 54 {y} Td (CSM202 | QUIZ) Tj ET']; y-=19
  o += [f'BT /F1 10 Tf {col(GREY)} rg 54 {y} Td (Statistical Inference and Regression Analysis - Lectures 08-11) Tj ET']; y-=22
  o += [f'0.72 0.78 0.82 RG 0.7 w 54 {y} m 541 {y} l S']; y-=21
  o += [f'BT /F1 9 Tf 54 {y} Td (Name: ____________________________) Tj 282 0 Td (Student ID: __________________) Tj ET']; y-=20
  o += [f'BT /F1 9 Tf 54 {y} Td (Class/Section: ____________________) Tj 282 0 Td (Date: ________________________) Tj ET']; y-=28
  o += [f'0.95 0.97 0.98 rg 54 {y-27} 487 34 re f',f'BT /F2 9 Tf {col(BLUE)} rg 63 {y-7} Td (TOTAL: 40 MARKS    |    SUGGESTED TIME: 60 MINUTES) Tj ET',f'BT /F1 8.5 Tf {col(BLUE)} rg 63 {y-20} Td (Answer all eight questions. Show working for numerical questions and state conclusions in context.) Tj ET',f'BT /F1 8.5 Tf {col(BLUE)} rg 63 {y-31} Td (Unless specified otherwise, use a 5% significance level.) Tj ET']; y-=53
 o += [f'BT /F2 12 Tf {col(BLUE)} rg 54 {y} Td ({esc(title)}) Tj ET']; y-=9
 o += [f'0.78 0.82 0.85 RG 0.6 w 54 {y} m 541 {y} l S']; return o,y-20
def q(o,y,n,title,parts,lines=2):
 o += [f'BT /F2 9.5 Tf {col(BLUE)} rg 54 {y} Td (Question {n}. {esc(title)}) Tj 440 0 Td ([5 marks]) Tj ET']; y-=15
 for text,indent in parts:
  for i,line in enumerate(textwrap.wrap(text,width=91 if indent else 99,break_long_words=False,break_on_hyphens=False) or ['']):
   o += [f'BT /F1 8.8 Tf 0.10 0.15 0.19 rg {72 if indent else 54} {y} Td ({esc(("    " if indent and i==0 else "       " if indent else "   " if i else "")+line)}) Tj ET']; y-=12
  y-=2
 y-=2
 for _ in range(lines): o += [f'0.82 0.86 0.88 RG 0.5 w 72 {y} m 541 {y} l S']; y-=18
 return y-8
def foot(o,n): o += ['0.82 0.86 0.88 RG 0.6 w 54 39 m 541 39 l S',f'BT /F1 8 Tf {col(GREY)} rg 54 25 Td (CSM202 - Quiz - Lectures 08-11) Tj 411 0 Td (Page {n} of 3) Tj ET']
o,y=start('PART I - SAMPLING AND ONE-SAMPLE INFERENCE',True)
y=q(o,y,1,'Sampling distribution',[('A population has mean 72 and standard deviation 16. A random sample of 64 observations is selected. Assume the sampling distribution of the sample mean is approximately normal.',False),('(a) State the mean and standard error of the sampling distribution of the sample mean. (2 marks)',True),('(b) Find the probability that the sample mean exceeds 76. Show the standardisation used. (3 marks)',True)],3)
y=q(o,y,2,'Confidence interval',[('A sample of 50 observations has mean 18.4 and sample standard deviation 4.2. Construct a 95% confidence interval for the population mean using the normal critical value 1.96. Show the standard error and margin of error, then interpret the interval in context. (5 marks)',False)],3)
y=q(o,y,3,'One-sample test for a mean',[('A manufacturer claims that the mean fill volume is 500 ml. A random sample of 36 containers has mean 512 ml. The population standard deviation is known to be 30 ml. At the 5% significance level, test whether the population mean differs from 500 ml. State the hypotheses, calculate the test statistic, give the decision rule or p-value, and state your conclusion. (5 marks)',False)],3); foot(o,1); pages.append(o)
o,y=start('PART II - HYPOTHESIS TESTING AND ANALYSIS OF VARIANCE')
y=q(o,y,4,'Hypothesis-testing decisions',[('A researcher conducts a hypothesis test at significance level alpha = 0.05.',False),('(a) Explain what a Type I error means in this setting. (2 marks)',True),('(b) Explain what a Type II error means. (2 marks)',True),('(c) State the relationship between the significance level and the probability of a Type I error. (1 mark)',True)],3)
y=q(o,y,5,'Two-sample test for means',[('Two independent groups have these summaries: Group A, n = 25, mean = 82, standard deviation = 8; Group B, n = 25, mean = 76, standard deviation = 10. Assume independent normal populations with equal variances. Test at the 5% level whether the population means differ. State H0 and H1, calculate the pooled-variance t statistic and degrees of freedom, and give a conclusion. Use a two-sided critical value of 2.01. (5 marks)',False)],4)
y=q(o,y,6,'One-way ANOVA',[('A one-way ANOVA compares mean outcomes for four teaching methods. The calculated F statistic is 4.80 and the critical value is 3.20.',False),('(a) State the null and alternative hypotheses in terms of the four population means. (2 marks)',True),('(b) Identify the test decision and explain what it means about the group means. (2 marks)',True),('(c) Explain why a significant ANOVA result does not identify which specific methods differ. (1 mark)',True)],3); foot(o,2); pages.append(o)
o,y=start('PART III - REGRESSION ANALYSIS')
y=q(o,y,7,'Interpreting a fitted regression line',[('A fitted regression model is yhat = 12 + 2.5x, where x is hours studied and y is the predicted quiz score.',False),('(a) Interpret the slope in context. (2 marks)',True),('(b) Predict the score for a student who studied for 8 hours. (1 mark)',True),('(c) A student who studied 8 hours scored 34. Calculate the residual using residual = observed - predicted, and interpret its sign. (2 marks)',True)],4)
y=q(o,y,8,'OLS, gradient descent, and mean squared error',[('(a) State the quantity that ordinary least squares (OLS) minimises when fitting a regression model. (2 marks)',False),('(b) Describe how gradient descent updates model parameters and explain the role of the learning rate. (2 marks)',False),('(c) Write the formula for mean squared error (MSE) for n observed values y_i and predictions yhat_i. (1 mark)',False)],5)
o += [f'BT /F1 8 Tf {col(GREY)} rg 220 116 Td (END OF QUIZ) Tj ET']; foot(o,3); pages.append(o)
objs=[]
def obj(b): objs.append(b); return len(objs)
cat=obj(b''); rootpages=obj(b''); f1=obj(b'<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>'); f2=obj(b'<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>'); kids=[]
for ops in pages:
 s='\n'.join(ops).encode('latin-1'); c=obj(b'<< /Length '+str(len(s)).encode()+b' >>\nstream\n'+s+b'\nendstream')
 kids.append(obj(f'<< /Type /Page /Parent {rootpages} 0 R /MediaBox [0 0 {W} {H}] /Resources << /Font << /F1 {f1} 0 R /F2 {f2} 0 R >> >> /Contents {c} 0 R >>'.encode()))
objs[cat-1]=f'<< /Type /Catalog /Pages {rootpages} 0 R >>'.encode(); objs[rootpages-1]=f'<< /Type /Pages /Kids [{" ".join(str(i)+" 0 R" for i in kids)}] /Count 3 >>'.encode()
pdf=bytearray(b'%PDF-1.4\n%\xe2\xe3\xcf\xd3\n'); offsets=[0]
for i,b in enumerate(objs,1): offsets.append(len(pdf)); pdf.extend(f'{i} 0 obj\n'.encode()+b+b'\nendobj\n')
x=len(pdf); pdf.extend(f'xref\n0 {len(objs)+1}\n0000000000 65535 f \n'.encode())
for off in offsets[1:]: pdf.extend(f'{off:010d} 00000 n \n'.encode())
pdf.extend(f'trailer\n<< /Size {len(objs)+1} /Root {cat} 0 R >>\nstartxref\n{x}\n%%EOF\n'.encode()); OUT.parent.mkdir(parents=True,exist_ok=True); OUT.write_bytes(pdf)
print(f'Created {OUT.resolve()} ({len(pdf)} bytes, {len(pages)} pages)')
