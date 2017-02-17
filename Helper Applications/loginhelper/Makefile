CFLAGS=-isysroot /Developer/SDKs/MacOSX10.5.sdk -arch i386 -arch x86_64
LDFLAGS=-framework Cocoa -arch i386 -arch x86_64
SOURCES=loginhelper.m
OBJECTS=$(SOURCES:.m=.o)
EXECUTABLE=loginhelper

all: $(SOURCES) $(EXECUTABLE)
	
$(EXECUTABLE): $(OBJECTS) 
	$(CC) $(LDFLAGS) $(OBJECTS) -o $@

.cpp.o:
	$(CC) $(CFLAGS) $< -o $@
