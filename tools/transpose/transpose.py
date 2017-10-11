#!/usr/bin/env python
#By: Clayton Turner

#imports
import sys
import csv

# error
def stop_err( msg ):
    sys.stderr.write( "%s\n" % msg )
    sys.exit()

# main
def main():
    try:
        # retrieve file locations/names
        inputFile   = sys.argv[1]
        output  = sys.argv[2]

        # open input file        
        itemList = list()
        with open(inputFile) as infile:
            for line in infile:
                items = line.strip('\n').split('\t')
                itemList.append(items)
            rows = zip(*itemList)

        infile.close()

        # open output file
        outfile = open(output,'w')
        writer = csv.writer(outfile, delimiter='\t')

        # append data to output file
        for row in rows:
            writer.writerow(row)

        # close output file
        outfile.close()        

    except Exception, ex:
        stop_err('Error running transpose.py\n' + str(ex))

    # exit
    sys.exit(0)

if __name__ == "__main__":
    main()
