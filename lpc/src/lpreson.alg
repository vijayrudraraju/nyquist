(LPRESON-ALG
(NAME "lpreson")
(ARGUMENTS ("sound_type" "x_snd")("LVAL" "src")("time_type" "frame_time"))
(SUPPORT-FUNCTIONS "
    #include \"samples.h\"
")
(START (MIN x_snd))
(ALWAYS-SCALE x_snd)
(TERMINATE (MIN x_snd))
(LOGICAL-STOP (MIN x_snd))
(SAMPLE-RATE "x_snd->sr")
(STATE  
        ("long" "fr_indx" "0")
        ("long" "ak_len" "0") ; length of coefs ak array 
        ("long" "frame_length" "(long) (frame_time*x_snd->sr)") ; samples length
        ("LVAL" "src" "src")
        ("LVAL" "array" "NULL")
        ("double *" "ak_coefs" "NULL")  ; coefs array
        ("double *" "zk_buf" "NULL")  ; last values of output
        ("double" "gain" "1.0")
        ("long" "index" "0")
                
     )

(OUTER-LOOP "
      if (susp->src == NULL) {
out:        togo = 0;     /* indicate termination */
            break;        /* we're done */
      }

      if(susp->fr_indx >= susp->frame_length)
             susp->fr_indx -= susp->frame_length;
      
      if (susp->fr_indx==0)
      {
         long i;
         susp->array = xleval(cons(s_send, cons(susp->src, consa(s_next))));
         if (susp->array == NULL) {
            susp->src = NULL;
            goto out;
         }
/* en susp->array tenemos la lista proporcionada por el objeto */
         else if (!listp(susp->array))
            xlerror(\"list expected\", susp->array);

         susp->gain = getflonum(car(susp->array));
         susp->array=car(cdr(susp->array)); 
         if (!vectorp(susp->array)) {
            xlerror(\"array expected\", susp->array);
         }
         else if (susp->ak_coefs == NULL) {
            susp->ak_len = getsize(susp->array);
            if (susp->ak_len < 1) xlerror(\"array has no elements\", susp->array);
            susp->ak_coefs = (double *) calloc(susp->ak_len, sizeof(double));
            susp->zk_buf = (double *) calloc(susp->ak_len, sizeof(double));
         }
         /* at this point we have a new array and a place to put ak coefs */

         for(i=0; i < susp->ak_len; i++) {
            LVAL elem = getelement(susp->array,i);
            if (ntype(elem) != FLONUM) {
                  xlerror(\"flonum expected\", elem);
            }
            susp->ak_coefs[i] = getflonum(elem);
         }

                  //  printf(\"NUEVO FILTRO: \");  /* here for debug */
                  //  for(k=0; k < susp->ak_len; k++) printf(\" %g \", susp->ak_coefs[k]);
                  //  printf(\"GAIN %g  AKLEN %d \", susp->gain, susp->ak_len);



         susp->array = NULL; /* free the array */
       

}    

       togo = min(susp->frame_length - susp->fr_indx, togo);

")

(INNER-LOOP-LOCALS "double z0; long xi; long xj;")

(INNER-LOOP "
             z0 = x_snd * gain;
             for (xi=0; xi < ak_len; xi++) {
                 xj = index + xi; if (xj >= ak_len) xj -= ak_len;
                 z0 += ak_coefs[xi] * zk_buf[xj];
             } 
             zk_buf[index] = z0;
             index++; if (index == ak_len) index = 0;
             fr_indx++; 
             output = (sample_type) z0;
")

(CONSTANT "frame_length" "src")

(FINALIZATION " free(susp->ak_coefs);
                free(susp->zk_buf);
")

)


