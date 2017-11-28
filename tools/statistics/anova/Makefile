# USAGE: make [install|clean]

# -------- VARIABLE --------

OBJ=anova.tgz
DEP=abims_anova.r abims_anova.xml static test-data


# ------------------------

all: $(OBJ)

$(OBJ): $(DEP)
	tar --exclude=".svn" -zchf $@ $^

# ------------------------

install: $(OBJ)
	mv *.tgz ~

clean:
	rm *.tgz

