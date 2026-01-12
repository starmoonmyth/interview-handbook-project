import { relationalStore } from '@kit.ArkData'
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { logger } from './logger'

const STORE_CONFIG: relationalStore.StoreConfig = {
  name: 'app_data.db',
  securityLevel: relationalStore.SecurityLevel.S1
}

const TABLE_NAME = 'app_info'

class DbHelper {
  private rdbStore: relationalStore.RdbStore | null = null

  async init(context: common.Context): Promise<void> {
    if (this.rdbStore) return

    try {
      this.rdbStore = await relationalStore.getRdbStore(context, STORE_CONFIG)
      await this.initTable()
    } catch (err) {
      logger.error('DbHelper', `Failed to init RdbStore: ${JSON.stringify(err)}`)
    }
  }

  private async initTable(): Promise<void> {
    if (!this.rdbStore) return
    const sql = `CREATE TABLE IF NOT EXISTS ${TABLE_NAME} (key TEXT PRIMARY KEY, value TEXT)`
    await this.rdbStore.executeSql(sql)
  }

  async setValue(key: string, value: string): Promise<void> {
    if (!this.rdbStore) {
      logger.error('DbHelper', 'RdbStore not initialized')
      return
    }

    const valueBucket: relationalStore.ValuesBucket = {
      key: key,
      value: value
    }

    try {
      // 尝试插入，如果存在则替换 (INSERT OR REPLACE)
      // 由于 ArkTS API 限制，这里先查询是否存在，或者直接使用 insert (如果 key 冲突会抛错，可以捕获后 update)
      // 更简单的做法是：先查询，有则更新，无则插入。
      // 或者使用 replace 接口（如果支持）
      
      // 使用 upsert 逻辑
      const predicates = new relationalStore.RdbPredicates(TABLE_NAME)
      predicates.equalTo('key', key)
      const count = await this.queryCount(predicates)
      
      if (count > 0) {
        await this.rdbStore.update(valueBucket, predicates)
      } else {
        await this.rdbStore.insert(TABLE_NAME, valueBucket)
      }
    } catch (err) {
      logger.error('DbHelper', `Failed to set value: ${JSON.stringify(err)}`)
    }
  }

  async getValue(key: string): Promise<string | null> {
    if (!this.rdbStore) {
      logger.error('DbHelper', 'RdbStore not initialized')
      return null
    }

    const predicates = new relationalStore.RdbPredicates(TABLE_NAME)
    predicates.equalTo('key', key)
    
    let resultSet: relationalStore.ResultSet | null = null
    try {
      resultSet = await this.rdbStore.query(predicates, ['value'])
      if (resultSet.goToFirstRow()) {
        const value = resultSet.getString(resultSet.getColumnIndex('value'))
        return value
      }
    } catch (err) {
      logger.error('DbHelper', `Failed to get value: ${JSON.stringify(err)}`)
    } finally {
      if (resultSet) {
        resultSet.close()
      }
    }
    return null
  }

  private async queryCount(predicates: relationalStore.RdbPredicates): Promise<number> {
    if (!this.rdbStore) return 0
    let resultSet: relationalStore.ResultSet | null = null
    try {
        resultSet = await this.rdbStore.query(predicates, ['key'])
        return resultSet.rowCount
    } catch (e) {
        return 0
    } finally {
        if (resultSet) resultSet.close()
    }
  }
}

export const dbHelper = new DbHelper()
