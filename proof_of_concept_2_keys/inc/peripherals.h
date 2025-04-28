/* Prototypes for functions used to access physical memory addresses */

/* Open /dev/mem to give access to physical addresses */
int open_physical (int);

/* Close /dev/mem to give access to physical addresses */
void close_physical (int);

/* Establish a virtual address mapping for the physical addresses starting
* at base and extending by span bytes */
void * map_physical (int, unsigned int, unsigned int);

/* Close the previously-opened virtual address mapping */
int unmap_physical (void *, unsigned int);