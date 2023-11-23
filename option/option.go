package option

import (
	"errors"
	"github.com/doug-martin/goqu/v9"
	_ "github.com/doug-martin/goqu/v9/dialect/mysql"
	_ "github.com/go-sql-driver/mysql"
	"strings"
)

type Option func(*defaultOptions)
type defaultOptions struct {
	wrapper      goqu.DialectWrapper
	fields       []interface{}
	desc         string
	asc          string
	group        string
	having       string
	offset       uint
	limit        uint
	errDoNothing bool // 插入出错跳过
	errDoUpdate  bool // 存在则更新
	exp          []goqu.Expression
	set          goqu.Record
	uniqueKey    string
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
	if strings.Contains(table, "`") {
		table = strings.ReplaceAll(table, "`", "")
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
	if strings.Contains(table, "`") {
		table = strings.ReplaceAll(table, "`", "")
	}
	return df.wrapper.Delete(table).Where(df.exp...).ToSQL()
}

func GenInstall(table string, rows interface{}, opts ...Option) (string, []interface{}, error) {
	df := newDefaultOptions()
	for _, apply := range opts {
		apply(df)
	}
	if strings.Contains(table, "`") {
		table = strings.ReplaceAll(table, "`", "")
	}
	if df.errDoNothing {
		return df.wrapper.Insert(table).OnConflict(goqu.DoNothing()).Rows(rows).ToSQL()
	}
	if df.errDoUpdate {
		// 存在则更新,有且只能有一个更新字段.若存在多个则不会生效
		if len(df.set.Cols()) == 0 {
			return "", nil, errors.New("the update record error")
		}
		if df.uniqueKey == "" {
			return "", nil, errors.New("the UniqueKey error")
		}
		return df.wrapper.Insert(table).OnConflict(goqu.DoUpdate(df.uniqueKey, df.set)).Rows(rows).ToSQL()
	}
	return df.wrapper.Insert(table).Rows(rows).ToSQL()
}

func GenUpdate(table string, opts ...Option) (string, []interface{}, error) {
	df := newDefaultOptions()
	for _, apply := range opts {
		apply(df)
	}
	if strings.Contains(table, "`") {
		table = strings.ReplaceAll(table, "`", "")
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
func WithErrDoNothing() Option {
	return func(obj *defaultOptions) {
		obj.errDoNothing = true
		obj.errDoUpdate = false
	}
}

func WithErrDoUpdate() Option {
	return func(obj *defaultOptions) {
		obj.errDoNothing = false
		obj.errDoUpdate = true
	}
}

// WithUniKey 唯一索引
func WithUniKey(in string) Option {
	return func(obj *defaultOptions) {
		obj.uniqueKey = in
	}
}
