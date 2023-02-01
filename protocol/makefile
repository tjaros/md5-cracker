build:
	latexmk -f -pdf --shell-escape Main.tex

clean:
	latexmk -c
	rm -rf Main.run.xml Main.bbl Main.tdo Main.todos Main.ex Main.a* Main.g* Main.ist Sources/*.aux Sources/*.log Sources/*.fdb*

COUNT:=$(shell texcount Main.tex -char -inc | grep "Letters in text:" | tail -n1 | cut -f2- -d:)

count:
	@echo Letters: $(COUNT)
	@echo Pages: $(shell echo $(COUNT)/1800 | bc )/30

