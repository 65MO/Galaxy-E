
#include "deteclaunch.h"
#include <iostream>

class DetecLaunch;

int main(int argc, char *argv[])
{
	for(int i=1;i<argc;i++){	
		QString alire = QString(argv[i]);
		if(alire=="--help" || alire=="-h")  {std::cout<<"Help here https://github.com/YvesBas/Tadarida-D/blob/master/Manual_Tadarida-D.odt"<<std::endl ; return 0 ;}
	}
	
	std::cout<<"Salut"<<std::endl ;
    if(argc<1) return(-1);
    DetecLaunch *dl= new DetecLaunch();
    dl->treat(argc,argv);
    delete dl;
    exit(0);
}

