import psycopg2
import json

activities = {'INSERT':{'lojista':'Adicionar lojista',
                           'entregador':'Adicionar entregador',
                           'item':'Adicionar item',
                           'pacote':'Empacotar itens',
                           'item_pacote':'Seleção item',
                           'entrega':'Marcar entrega',
                           'pacote_entrega':'Seleção pacote'},
                 'UPDATE':{'lojista':'Alterar lojista',
                           'entregador':'Atualizar entregador',
                           'entrega':{'status':{'"Entregue"':'Entrega concluída',
                                                '"Falha"':'Entrega falha'
                                                }
                                      }
                           }
                 }

attributes = {'lojista':['CNPJ','nome','endereco','id'],
              'item':['nome','quantidade','destinatario','destino','prioridade','codigo_pedido','id','fk_lojista_id'],
              'pacote':['peso','fragil','id'],
              'entrega':['status','data','id','fk_entregador_id'],
              'entregador':['nome','veiculo','nivel','id'],
              'item_pacote':['fk_pacote_id','fk_item_id'],
              'pacote_entrega':['fk_pacote_id','fk_entrega_id']}

def checkActivity(quer, table, field = None, n_value = None):
    if (field):
        if type(activities[quer][table]) is dict:
            if n_value and (type(activities[quer][table][field]) is dict):
                return activities[quer][table][field][n_value]
            return activities[quer][table][field]
    return activities[quer][table]

def checkAttributes(table):
    return attributes[table]

with open('Schemas/ocel-log.json', 'r') as openfile:
    json_object = json.load(openfile)


conn = psycopg2.connect(host="localhost",
                        database = "ocelproject",
                        user="postgres",
                        password="admin")
cur = conn.cursor()

cur.execute('SELECT * FROM changelog')
changetable = cur.fetchall()

i = 0
for change in changetable:
    i += 1
    json_object['ocel:events'][str(i)] = {}
    if (change[4] == 'all'):
        activity = checkActivity(change[0], change[1])
    else:
        activity = checkActivity(change[0], change[1], change[4], change[3])
    timestamp = change[-1].strftime('%Y-%m-%d %H:%M:%S.%f')

    # Starting the event tags
    json_object['ocel:events'][str(i)]['ocel:activity'] = activity
    json_object['ocel:events'][str(i)]['occel:timestamp'] = timestamp
    json_object['ocel:events'][str(i)]['ocel:omap'] = []
    json_object['ocel:events'][str(i)]['ocel:vmap'] = {}
    if (change[0] == 'INSERT'):
        # Taking attributes names and values
        attrib = checkAttributes(change[1])
        lattrib = change[3][1:-1].split(sep=',')
        
        # Generating object name
        try:
            objId = lattrib[attrib.index('id')]
        except:
            objId = i
        objName = change[1] + str(objId)

        # Creating object in objects label
        json_object['ocel:objects'][objName] = { 'ocel:type': change[1],
                                                 'ocel:ovmap': {}}

        # Attributes added in the event and object tags
        for j in range(0,len(attrib)):
            json_object['ocel:events'][str(i)]['ocel:vmap'][attrib[j]] = lattrib[j]
            json_object['ocel:objects'][objName]['ocel:ovmap'][attrib[j]] = lattrib[j]

        # Object name added in omap
        json_object['ocel:events'][str(i)]['ocel:omap'].append(objName)
    else:
        # Find first object with the attribute being changed
        fattrib = change[2]
        lattrib = change[3]
        attrib = change[4]
        objName = "."

        for obj in json_object['ocel:objects']:
            if not obj.startswith(change[1]):
                continue
            try:
                int(obj[len(change[1]):])
            except:
                continue
            if json_object['ocel:objects'][obj]['ocel:ovmap'][attrib] == fattrib:
                objName = obj
                break

        # With the objName, change the attribute value
        json_object['ocel:objects'][objName]['ocel:ovmap'][attrib] = lattrib

        # Add the object name in omap
        json_object['ocel:events'][str(i)]['ocel:omap'].append(objName)

        # Add the attribute changed in the event vmap
        json_object['ocel:events'][str(i)]['ocel:vmap'][attrib] = lattrib

conn.close()
with open('Schemas/generated-ocel-log.json', 'w', encoding='utf-8') as f:
    json.dump(json_object, f, ensure_ascii=False, indent=4)
