FC=ifort
BUFR_LIB=-L$(BUFR_DIR)/lib -lbufr_v10.2.5
FCFLAGS=-O2 -traceback #-check
LDFLAGS=$(BUFR_LIB)
INCFLAGS=

#objects = test.o init_nemsioatm2nc.o vars_nemsioatm2nc.o convert_nemsioatm2nc.o mainatm.o
objects = prepbufr_append_surface.new.o

prepbufr_append_surface.x: prepbufr_append_surface.new.o
	$(FC) $(FCFLAGS) -o prepbufr_append_surface.x $(objects) $(LDFLAGS) $(INCFLAGS)

prepbufr_append_surface.new.o:  prepbufr_append_surface.new.f90
	$(FC) $(FCFLAGS) $(LDFLAGS) $(INCFLAGS) -c prepbufr_append_surface.new.f90

clean:
	rm prepbufr_append_surface.x *.o

