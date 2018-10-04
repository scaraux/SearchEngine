
/* This is the Porter stemming algorithm, coded up as thread-safe ANSI C
   by the author.

   It may be be regarded as cononical, in that it follows the algorithm
   presented in

   Porter, 1980, An algorithm for suffix stripping, Program, Vol. 14,
   no. 3, pp 130-137,

   only differing from it at the points marked --DEPARTURE-- below.

   See also http://www.tartarus.org/~martin/PorterStemmer

   The algorithm as described in the paper could be exactly replicated
   by adjusting the points of DEPARTURE, but this is barely necessary,
   because (a) the points of DEPARTURE are definitely improvements, and
   (b) no encoding of the Porter stemmer I have seen is anything like
   as exact as this version, even with the points of DEPARTURE!

   You can compile it on Unix with 'gcc -O3 -o stem stem.c' after which
   'stem' takes a list of inputs and sends the stemmed equivalent to
   stdout.

   The algorithm as encoded here is particularly fast.

   Release 1: the basic non-thread safe version

   Release 2: this thread-safe version

   Release 3: 11 Apr 2013, fixes the bug noted by Matt Patenaude (see the
       basic version for details)

   Release 4: 25 Mar 2014, fixes the bug noted by Klemens Baum (see the
       basic version for details)
*/

#ifndef stemming_h
#define stemming_h

struct stemmer;

extern struct stemmer * create_stemmer(void);
extern void free_stemmer(struct stemmer * z);

extern int stemm(struct stemmer * z, char * b, int k);

#endif /* stemming_h */
