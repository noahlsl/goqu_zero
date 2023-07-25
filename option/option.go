package option

import (
	"github.com/doug-martin/goqu/v9"
	_ "github.com/doug-martin/goqu/v9/dialect/mysql"
	_ "github.com/go-sql-driver/mysql"
)

type Option func(*defaultOptions)
type defaultOptions struct {
	wrapper goqu.DialectWrapper
	fields  []interface{}
	desc    string
	asc     string
	group   string
	having  string
	offset  uint
	limit   uint
	exp     []goqu.Expression
	set     goqu.Record
}

func newDefaultOptions() *defaultOptions {
	return &defaultOptions{
		wrapper: goqu.Dialect("mysql"),
	}
}
func GenSelect(table string, opts ...Option) (string, []interface{}, error) {
	df := newDefaultOptions()
	for _, apply := range opts {
		apply(df)
	}
	w := df.wrapper.From(table).Select().Where(df.exp...)
	if len(df.fields) != 0 {
		w = w.Select(df.fields...)
	}
	if df.asc != "" {
		w = w.Order(goqu.C(df.asc).Asc())
	}
	if df.desc != "" {
		w = w.Order(goqu.C(df.desc).Desc())
	}
	if df.group != "" {
		w = w.GroupByAppend(df.group)
	}
	if df.limit != 0 {
		w = w.Offset(df.offset).Limit(df.limit)
	}
	return w.ToSQL()
}

func GenDelete(table string, opts ...Option) (string, []interface{}, error) {
	df := newDefaultOptions()
	for _, apply := range opts {
		apply(df)
	}
	return df.wrapper.Delete(table).Where(df.exp...).ToSQL()
}

func GenInstall(table string, rows interface{}) (string, []interface{}, error) {
	df := newDefaultOptions()
	return df.wrapper.Insert(table).Rows(rows).ToSQL()
}

func GenUpdate(table string, opts ...Option) (string, []interface{}, error) {
	df := newDefaultOptions()
	for _, apply := range opts {
		apply(df)
	}
	return df.wrapper.From(table).Update().Where(df.exp...).Set(df.set).ToSQL()
}

func WithFields(fields ...string) Option {
	return func(obj *defaultOptions) {
		for _, field := range fields {
			obj.fields = append(obj.fields, goqu.L(field))
		}
	}
}

func WithAsc(field string) Option {
	return func(obj *defaultOptions) {
		obj.asc = field
	}
}

func WithGroup(field string) Option {
	return func(obj *defaultOptions) {
		obj.group = field
	}
}

func WithHaving(field string) Option {
	return func(obj *defaultOptions) {
		obj.having = field
	}
}

func WithExpression(exp ...goqu.Expression) Option {
	return func(obj *defaultOptions) {
		obj.exp = append(obj.exp, exp...)
	}
}
func WithDesc(field string) Option {
	return func(obj *defaultOptions) {
		obj.desc = field
	}
}
func WithSetRecord(set goqu.Record) Option {
	return func(obj *defaultOptions) {
		obj.set = set
	}
}

func WithPageSize(page, size uint) Option {
	return func(obj *defaultOptions) {
		if page != 0 {
			obj.offset = (page - 1) * size
		}
		obj.limit = size
	}
}
