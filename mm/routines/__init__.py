import logging
import re

import sqlalchemy.orm
import sqlalchemy.exc

import mm.db

_LOGGER = logging.getLogger(__name__)

_DB_ERROR_RX = r"\(OperationalError\) \([0-9]+, (['\"])(.+)\1\)"

_DB_SESSION = \
    sqlalchemy.orm.scoped_session(
        sqlalchemy.orm.sessionmaker(
            bind=mm.db.ENGINE))


class _BlobArgumentWrapper(object):
    def __init__(self, data):
        self.__data = data
        self.__encoded = None

    @property
    def encoded(self):
        if self.__encoded is None:
            self.__encoded = self.__data.encode('hex')

        return ('0x' + self.__encoded) if self.__encoded != '' else "''"


class RoutinesBase(object):
    """The routines base-class."""

    noun = None

    def __init__(self, connection=None):
        """Initialize the base routines object. We can take a specific 
        connection to use.
        """

        assert self.noun is not None, "Noun is not set."

        self.__connection = connection

    def __get_session(self):
        kwargs = {}
        if self.__connection is not None:
            kwargs['bind'] = self.__connection

        return _DB_SESSION(**kwargs)

    def get_one_record(self, *args, **kwargs):
        """This is an older interface that should now only be used by call(), 
        above.
        """

        records = self.call(*args, **kwargs)
        records = list(records)
        len_ = len(records)

        if len_ != 1:
            raise ValueError("We were told to only return one record, but "
                             "this did not match what was given: (%d)" % 
                             (len_,))

        return records[0]

    def __build_query(self, routine, parameters):
        """Return a queury that uses traditional/proper parameters."""

        parameter_names = []
        replacements = {}
        for i, value in enumerate(parameters):
            name = 'arg' + str(i)

            parameter_names.append(name)
            replacements[name] = value

        parameter_pieces = []
        for i, name in enumerate(parameter_names):
            if i > 0:
                parameter_pieces.append(', ')

            # Embed encoded blobs directly.
            if issubclass(replacements[name].__class__, _BlobArgumentWrapper) is True:
                parameter_pieces.append(replacements[name].encoded)
                del replacements[name]
            else:
                parameter_pieces.append(':' + name)

        query = "CALL " + routine + "(" + ''.join(parameter_pieces) + ")"

        return (query, replacements)

    def __build_raw_query(self, routine, parameters):
        """Return a query that uses raw string-replacement for parameters.

        The parameters will still be escaped before replaced-into the query (by 
        sqlalchemy).
        """

        parameter_names = []
        replacements = {}

        for i, value in enumerate(parameters):
            name = 'arg' + str(i)

            parameter_names.append(name)
            replacements[name] = value

        parameter_phrase = ', '.join([('%(' + p + ')s') for p in parameter_names])

        query = "CALL " + routine + "(" + parameter_phrase + ")"
        return (query, replacements)

    def call(self, routine, *args):
        """This is a newer, less-verbose interface that calls the old 
        philistine one. This should be used.
        """

        (query, replacements) = self.__build_query(routine, args)

        return self.__execute_text(query, **replacements)

    def get_resultsets(self, routine, *args):
        """Return a list of lists of dictionaries, for when a query returns 
        more than one resultset.
        """

        (query, replacements) = self.__build_raw_query(routine, args)

        # Grab a raw connection from the connection-pool.
        connection = mm.db.ENGINE.raw_connection()

        sets = []

        try:
            cursor = connection.cursor()

            cursor.execute(query, replacements)

            while 1:
                #(column_name, type_, ignore_, ignore_, ignore_, null_ok, column_flags)
                names = [c[0] for c in cursor.description]

                set_ = []
                while 1:
                    row_raw = cursor.fetchone()
                    if row_raw is None:
                        break

                    row = dict(zip(names, row_raw))
                    set_.append(row)

                sets.append(list(set_))

                if cursor.nextset() is None:
                    break

# TODO(dustin): nextset() doesn't seem to be sufficiant to tell the end.
                if cursor.description is None:
                    break
        finally:
            # Return the connection to the pool (won't actually close).
            connection.close()

        return sets

    def __execute_text(self, query, **replacements):
        """This is an older interface that should now only be used by call(), 
        above.
        """

        # We've had persistent and long-term issues where we can't access tables 
        # from another client because they're locked, as well as getting the 
        # "gone away" error quite frequenctly. Per the documentation, apparently 
        # it is common to -not- reuse the same session from request to request,
        # and we believe this to be the problem. Hopefully it's fixed, now.
        #
        # REF: http://docs.sqlalchemy.org/en/rel_0_9/orm/session.html#when-do-i-construct-a-session-when-do-i-commit-it-and-when-do-i-close-it
        session = self.__get_session()
        
        try:
            records = session.execute(query, replacements)
        except:
            _LOGGER.exception("Query failure:\n%s", query)

            raise

        # Verifying that we have a realized list of results before we commit 
        # the transaction.

        try:
            records = list(records)
        finally:
            session.commit()

        for record in records:
            yield dict(record)

    def encode_string_to_hex(self, data):
        """Use hex-notation to represent a literal (useful for sending 
        blobs/binary content into routines).
        """

        return _BlobArgumentWrapper(data)

    def extract_message_from_error(self, e):
        assert issubclass(e.__class__, sqlalchemy.exc.OperationalError),\
               "We can't extract the message from an unsupported exception."

        raw_message = str(e)
        r = re.match(_DB_ERROR_RX, raw_message)
        if r is None:
            raise ValueError("Could not parse registration error: "
                             "[%s]" % (raw_message,))

        return r.group(2)
