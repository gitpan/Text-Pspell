#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <pspell/pspell.h>

#define MAX_ERRSTR_LEN 1000

typedef struct {
    PspellCanHaveError  *ret;
    PspellManager       *manager;
    PspellConfig        *config;
    char                lastError[MAX_ERRSTR_LEN+1];
    int                 errnum;
} ex1_struct;

char *Option_List[] = {
      "language-tag", "spelling", "jargon",
      "word-list-path", "module-search-order",
      "encoding", "ignore", 
      "personal", "repl", "save-repl", "ignore-repl", 
      "sug-mode", "run-together",
      "master", "master-flags", "module",
      0	      
};

int _create_manager(ex1_struct *self)
{
        PspellCanHaveError *ret;    

        ret = new_pspell_manager(self->config);
        delete_pspell_config(self->config);
        self->config=NULL;
   
        if ( (self->errnum = pspell_error_number(ret) ) )
        {
            strncpy(self->lastError, (char*) pspell_error_message(ret), MAX_ERRSTR_LEN);
            return 0;
        }

        self->manager = to_pspell_manager(ret);
        self->config  = pspell_manager_config(self->manager);
        return 1;
}        




MODULE = Text::Pspell		PACKAGE = Text::Pspell


# Make sure that we have at least xsubpp version 1.922.
REQUIRE: 1.922

ex1_struct *
new(CLASS)
	char *CLASS
    CODE:
	    RETVAL = (ex1_struct*)safemalloc( sizeof( ex1_struct ) );
    	if( RETVAL == NULL ){
    		warn("unable to malloc ex1_struct");
    		XSRETURN_UNDEF;
    	}
    	memset( RETVAL, 0, sizeof( ex1_struct ) );

        // create the configuration
        RETVAL->config = new_pspell_config();

        // Set initial default
        // pspell_config_replace(RETVAL->config, "language-tag", "en");  // default language is 'EN'
	
    OUTPUT:
    	RETVAL


void
DESTROY(self)
	ex1_struct *self
    CODE:
        if ( self->manager )
            delete_pspell_manager(self->manager); 
        safefree( (char*)self );


int
create_manager(self)
	ex1_struct *self
    CODE:
	    if ( !_create_manager(self) )
	        XSRETURN_UNDEF;

        RETVAL = 1;	        

	OUTPUT:
	    RETVAL

int
print_config(self)
	ex1_struct *self
    PREINIT:
        char ** opt;
	CODE:
	    self->lastError[0] = '\0';

	    /*
	    if (!self->manager)
	    {
	        strcpy(self->lastError, "Can't list config, no manager available");
	        XSRETURN_UNDEF;
	    }
	    */

	    for (opt=Option_List; *opt; opt++) 
            PerlIO_printf(PerlIO_stdout(),"%20s:  %s\n", *opt, pspell_config_retrieve(self->config, *opt) );

	    RETVAL = 1;

	OUTPUT:
	    RETVAL


int
set_option(self, tag, val )
	ex1_struct *self
	char *tag
    char *val
    CODE:
	    self->lastError[0] = '\0';

        pspell_config_replace(self->config, tag, val );

	    if ( (self->errnum = pspell_config_error_number( (const PspellConfig *)self->config) ) )
        {
	        strcpy(self->lastError, pspell_config_error_message( (const PspellConfig *)self->config ) );
            XSRETURN_UNDEF;
        }

        RETVAL = 1;
	OUTPUT:
	    RETVAL
    


int
remove_option(self, tag )
	ex1_struct *self
	char *tag
    CODE:
	    self->lastError[0] = '\0';

        pspell_config_remove(self->config, tag );
        
	    if ( (self->errnum = pspell_config_error_number( (const PspellConfig *)self->config) ) )
        {
	        strcpy(self->lastError, pspell_config_error_message( (const PspellConfig *)self->config ) );
            XSRETURN_UNDEF;
        }

        RETVAL = 1;
	OUTPUT:
	    RETVAL

char *
get_option(self, val)
	ex1_struct *self
	char *val
    CODE:
	    self->lastError[0] = '\0';

	    RETVAL = (char *)pspell_config_retrieve(self->config, val);

	    if ( (self->errnum = pspell_config_error_number( (const PspellConfig *)self->config) ) )
        {
	        strcpy(self->lastError, pspell_config_error_message( (const PspellConfig *)self->config ) );
            XSRETURN_UNDEF;
        }

    OUTPUT:
	    RETVAL


char *
errstr(self)
	ex1_struct *self
    CODE:
        RETVAL = (char*) self->lastError;
    OUTPUT:
        RETVAL

int
errnum(self)
	ex1_struct *self
    CODE:
        RETVAL = self->errnum;
    OUTPUT:
        RETVAL


int
check(self,word)
	ex1_struct *self
	char * word
	CODE:
	    self->lastError[0] = '\0';
	    self->errnum = 0;
	    
	    if (!self->manager && !_create_manager(self) )
	        XSRETURN_UNDEF;


        RETVAL = pspell_manager_check(self->manager, word, -1);
        if (RETVAL != 1 && RETVAL != 0)
        {
            self->errnum = pspell_manager_error_number( (const PspellManager *)self->manager );
            strncpy(self->lastError, (char*) pspell_manager_error_message(self->manager), MAX_ERRSTR_LEN);
            XSRETURN_UNDEF;
	    }
    OUTPUT:
	    RETVAL
        
int
suggest(self, word)
	ex1_struct *self
	char * word
	PREINIT:
	    const PspellWordList *wl;
	    PspellStringEmulation *els;
	    const char *suggestion;
	PPCODE:
	    self->lastError[0] = '\0';
	    self->errnum = 0;
	    
	    if (!self->manager && !_create_manager(self) )
	        XSRETURN_UNDEF;

        wl = pspell_manager_suggest(self->manager, word, -1);
        if (!wl)
        {
            self->errnum = pspell_manager_error_number( (const PspellManager *)self->manager );
            strncpy(self->lastError, (char*) pspell_manager_error_message(self->manager), MAX_ERRSTR_LEN);
            XSRETURN_UNDEF;
        }
  
        els = pspell_word_list_elements(wl);

        while ( (suggestion = pspell_string_emulation_next(els)) )
            PUSHs(sv_2mortal(newSVpv( (char *)suggestion ,0 )));

        delete_pspell_string_emulation(els);


int
add_to_personal(self,word)
	ex1_struct *self
	char * word
	CODE:
	    self->lastError[0] = '\0';
	    self->errnum = 0;
	    
	    if (!self->manager && !_create_manager(self) )
	        XSRETURN_UNDEF;


        RETVAL = pspell_manager_add_to_personal(self->manager, word, -1);
        if ( !RETVAL )
        {
            self->errnum = pspell_manager_error_number( (const PspellManager *)self->manager );
            strncpy(self->lastError, (char*) pspell_manager_error_message(self->manager), MAX_ERRSTR_LEN);
            XSRETURN_UNDEF;
	    }
    OUTPUT:
	    RETVAL

int
add_to_session(self,word)
	ex1_struct *self
	char * word
	CODE:
	    self->lastError[0] = '\0';
	    self->errnum = 0;
	    
	    if (!self->manager && !_create_manager(self) )
	        XSRETURN_UNDEF;


        RETVAL = pspell_manager_add_to_session(self->manager, word, -1);
        if ( !RETVAL )
        {
            self->errnum = pspell_manager_error_number( (const PspellManager *)self->manager );
            strncpy(self->lastError, (char*) pspell_manager_error_message(self->manager), MAX_ERRSTR_LEN);
            XSRETURN_UNDEF;
	    }
    OUTPUT:
	    RETVAL



int
store_replacement(self,word,replacement)
	ex1_struct *self
	char * word
	char * replacement
	CODE:
	    self->lastError[0] = '\0';
	    self->errnum = 0;
	    
	    if (!self->manager && !_create_manager(self) )
	        XSRETURN_UNDEF;


        RETVAL = pspell_manager_store_replacement(self->manager, word, -1, replacement, -1);
        if ( !RETVAL )
        {
            self->errnum = pspell_manager_error_number( (const PspellManager *)self->manager );
            strncpy(self->lastError, (char*) pspell_manager_error_message(self->manager), MAX_ERRSTR_LEN);
            XSRETURN_UNDEF;
	    }
    OUTPUT:
	    RETVAL

int
save_all_word_lists(self)
	ex1_struct *self
	CODE:
	    self->lastError[0] = '\0';
	    self->errnum = 0;
	    
	    if (!self->manager && !_create_manager(self) )
	        XSRETURN_UNDEF;


        RETVAL = pspell_manager_save_all_word_lists(self->manager);
        if ( !RETVAL )
        {
            self->errnum = pspell_manager_error_number( (const PspellManager *)self->manager );
            strncpy(self->lastError, (char*) pspell_manager_error_message(self->manager), MAX_ERRSTR_LEN);
            XSRETURN_UNDEF;
	    }
    OUTPUT:
	    RETVAL
	    
int
clear_session(self)
	ex1_struct *self
	CODE:
	    self->lastError[0] = '\0';
	    self->errnum = 0;
	    
	    if (!self->manager && !_create_manager(self) )
	        XSRETURN_UNDEF;


        RETVAL = pspell_manager_clear_session(self->manager);
        if ( !RETVAL )
        {
            self->errnum = pspell_manager_error_number( (const PspellManager *)self->manager );
            strncpy(self->lastError, (char*) pspell_manager_error_message(self->manager), MAX_ERRSTR_LEN);
            XSRETURN_UNDEF;
	    }
    OUTPUT:
	    RETVAL
	    
                                       
