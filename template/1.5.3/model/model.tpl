package {{.pkg}}
{{if .withCache}}
import (
    "context"
    "github.com/noahlsl/goqu_zero/option"
    "github.com/zeromicro/go-zero/core/logx"
    "github.com/zeromicro/go-zero/core/stores/sqlx"
	"github.com/zeromicro/go-zero/core/stores/cache"
)
{{else}}

import (
    "context"
    "github.com/noahlsl/goqu_zero/option"
    "github.com/zeromicro/go-zero/core/logx"
	"github.com/zeromicro/go-zero/core/stores/sqlx"
)

{{end}}
var _ {{.upperStartCamelObject}}Model = (*custom{{.upperStartCamelObject}}Model)(nil)

type (
	// {{.upperStartCamelObject}}Model is an interface to be customized, add more methods here,
	// and implement the added methods in custom{{.upperStartCamelObject}}Model.
	{{.upperStartCamelObject}}Model interface {
        FindSum(ctx context.Context, field string, opts ...option.Option) (float64, error)
        FindCount(ctx context.Context, opts ...option.Option) (int64, error)
        First(ctx context.Context, opts ...option.Option) (*{{.upperStartCamelObject}}, error)
        FindAll(ctx context.Context, opts ...option.Option) ([]*{{.upperStartCamelObject}}, error)
        FindList(ctx context.Context, page, size uint, opts ...option.Option) ([]*{{.upperStartCamelObject}}, error)
        FindListWithTotal(ctx context.Context, page, size uint, opts ...option.Option) ([]*{{.upperStartCamelObject}}, int64, error)
        Trans(ctx context.Context, fn func(context context.Context, session sqlx.Session) error) error
        DeleteTx(ctx context.Context, session sqlx.Session, id interface{}, opts ...option.Option) error
        UpdateTx(ctx context.Context, session sqlx.Session, opts ...option.Option) error
        InstallTx(ctx context.Context, session sqlx.Session, in *ReportAgent) error
	}

	custom{{.upperStartCamelObject}}Model struct {
		*default{{.upperStartCamelObject}}Model
	}
)

// New{{.upperStartCamelObject}}Model returns a model for the database table.
func New{{.upperStartCamelObject}}Model(conn sqlx.SqlConn{{if .withCache}}, c cache.CacheConf, opts ...cache.Option{{end}}) {{.upperStartCamelObject}}Model {
	return &custom{{.upperStartCamelObject}}Model{
		default{{.upperStartCamelObject}}Model: new{{.upperStartCamelObject}}Model(conn{{if .withCache}}, c, opts...{{end}}),
	}
}

func (c custom{{.upperStartCamelObject}}Model) FindSum(ctx context.Context, field string, opts ...option.Option) (float64, error) {
	var resp float64
	opts = append(opts, option.WithFields(fmt.Sprintf("SUM(%s)", field)))
	query, params, err := option.GenSelect(c.table, opts...)
	if err != nil {
		return 0, err
	}

	logx.Debugf(query, params)
	err = c.QueryRowNoCacheCtx(ctx, &resp, query, params)
	if err != nil {
		return 0, err
	}

	return resp, nil
}

func (c custom{{.upperStartCamelObject}}Model) FindCount(ctx context.Context, opts ...option.Option) (int64, error) {
	var resp int64
	opts = append(opts, option.WithFields("COUNT(1)"))
	query, params, err := option.GenSelect(c.table, opts...)
	if err != nil {
		return 0, err
	}

	logx.Debugf(query, params)
	err = c.QueryRowNoCacheCtx(ctx, &resp, query, params)
	if err != nil {
		return 0, err
	}

	return resp, nil
}

func (c custom{{.upperStartCamelObject}}Model) First(ctx context.Context, opts ...option.Option) (*ReportAgent, error) {
	var resp *ReportAgent
	query, params, err := option.GenSelect(c.table, opts...)
	if err != nil {
		return nil, err
	}

	logx.Debugf(query, params)
	err = c.QueryRowNoCacheCtx(ctx, &resp, query, params)
	if err != nil {
		return nil, err
	}

	return resp, nil
}

func (c custom{{.upperStartCamelObject}}Model) FindAll(ctx context.Context, opts ...option.Option) ([]*ReportAgent, error) {
	var resp []*ReportAgent
	query, params, err := option.GenSelect(c.table, opts...)
	if err != nil {
		return nil, err
	}

	logx.Debugf(query, params)
	err = c.QueryRowNoCacheCtx(ctx, &resp, query, params)
	if err != nil {
		return nil, err
	}

	return resp, nil
}

func (c custom{{.upperStartCamelObject}}Model) FindList(ctx context.Context, page, size uint, opts ...option.Option) ([]*ReportAgent, error) {
	var resp []*ReportAgent
	opts = append(opts, option.WithPageSize(page, size))
	query, params, err := option.GenSelect(c.table, opts...)
	if err != nil {
		return nil, err
	}

	logx.Debugf(query, params)
	err = c.QueryRowNoCacheCtx(ctx, &resp, query, params)
	if err != nil {
		return nil, err
	}

	return resp, nil
}

func (c custom{{.upperStartCamelObject}}Model) FindListWithTotal(ctx context.Context, page, size uint, opts ...option.Option) ([]*ReportAgent, int64, error) {

	query, params, err := option.GenSelect(c.table, opts...)
	if err != nil {
		return nil, 0, err
	}

	logx.Debugf(query, params)
	var count int64
	err = c.QueryRowNoCacheCtx(ctx, &count, query, params)
	if err != nil {
		return nil, 0, err
	}

	if count == 0 {
		return nil, 0, err
	}

	opts = append(opts, option.WithPageSize(page, size))
	resp, err := c.FindList(ctx, page, size, opts...)
	if err != nil {
		return nil, 0, err
	}

	return resp, count, nil
}

func (c custom{{.upperStartCamelObject}}Model) Trans(ctx context.Context, fn func(context context.Context, session sqlx.Session) error) error {
	return c.TransactCtx(ctx, func(ctx context.Context, session sqlx.Session) error {
		return fn(ctx, session)
	})
}

func (c custom{{.upperStartCamelObject}}Model) DeleteTx(ctx context.Context, session sqlx.Session, id interface{}, opts ...option.Option) error {

	query, params, err := option.GenDelete(c.table, opts...)
	if err != nil {
		return err
	}

	var keys []string
	// TODO 自己实现删除其他缓存
	keys = append(keys, fmt.Sprintf("%v:%v", cacheReportAgentIdPrefix, id))
	err = c.CachedConn.DelCache(keys...)
	if err != nil {
		return err
	}

	_, err = session.ExecCtx(ctx, query, params)
	return err
}

func (c custom{{.upperStartCamelObject}}Model) UpdateTx(ctx context.Context, session sqlx.Session, opts ...option.Option) error {

	query, params, err := option.GenUpdate(c.table, opts...)
	if err != nil {
		return err
	}

	execCtx, err := session.ExecCtx(ctx, query, params)
	if err != nil {
		return err
	}

	id, err := execCtx.RowsAffected()
	if err != nil {
		return err
	}
	var keys []string
	// TODO 自己实现删除其他缓存
	keys = append(keys, fmt.Sprintf("%v:%v", cacheReportAgentIdPrefix, id))
	err = c.CachedConn.DelCache(keys...)
	if err != nil {
		return err
	}

	return err
}
func (c custom{{.upperStartCamelObject}}Model) InstallTx(ctx context.Context, session sqlx.Session, in *ReportAgent) error {

	query, params, err := option.GenInstall(c.table, in)
	if err != nil {
		return err
	}

	execCtx, err := session.ExecCtx(ctx, query, params)
	if err != nil {
		return err
	}

	id, err := execCtx.LastInsertId()
	if err != nil {
		return err
	}

	key := fmt.Sprintf("%v:%v", cacheReportAgentIdPrefix, id)
	err = c.CachedConn.SetCacheCtx(ctx, key, in)
	if err != nil {
		return err
	}

	return nil
}