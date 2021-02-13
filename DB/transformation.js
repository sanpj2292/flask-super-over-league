const originalData = require('./original-data');

const a  = [{
    "bucket": 1,
    "procedure_code": "90791",
    "total_charge_amount": "23440",
    "total_payment_amount": "13717.39",
    "total_adjustment_amount": "7619.95",
    "total": "2102.66"
},
{
    "bucket": 2,
    "procedure_code": "90791",
    "total_charge_amount": "23765",
    "total_payment_amount": "15152.41",
    "total_adjustment_amount": "7893.03",
    "total": "719.56"
},
{
    "bucket": 3,
    "procedure_code": "90791",
    "total_charge_amount": "3750",
    "total_payment_amount": "20623.64",
    "total_adjustment_amount": "11220.31",
    "total": "-28093.95"
},
];

function Tree (hierarchy, bucket1='0', bucket2='0', bucket3='0', bucket4='0', bucket5='0') {
    const obj = {
        '0-30': bucket1,
        '31-60': bucket2,
        '61-90': bucket3,
        '91-120': bucket4,
        '120+': bucket5,
        hierarchy,
        aggregate () {
            const total = Object.keys(this).reduce((agg, k) => { 
                if(k !== 'hierarchy' && k !== 'Total' && k !== 'aggregate') {
                    let number = parseFloat(this[k]);
                   return agg + number;
                }
                return agg + 0;
              }, 0);
              return total;
        },
    };
    Object.assign(this, obj, {});
    this.total = obj.aggregate();
    return this;
}


const b = [
    new Tree(['Procedure Code'], '2102.66', '719.56', '-28093.95', '0', '0'),
    new Tree(['Procedure Code', 'Charges'], '23440', '23765', '3750', '0', '0'),
    new Tree(['Procedure Code', 'Payments'], '13717.39', '15152.41', '20623.64', '0', '0'),
    new Tree(['Procedure Code', 'Adjustments'], '7619.95', '7893.03', '11220.31', '0', '0'),
];

function transform(requestData = a, groupColumn='procedure_code') {
    const transformedData = {};
    requestData.forEach(data => {
        let dataListObject = {
            groupTotals: [],
            charges: [],
            payments: [],
            Adjustments: []
        };
        const ind = data['bucket'] - 1;
        
        if (transformedData[data[groupColumn]]) {
            dataListObject = transformedData[data[groupColumn]];
        }
        dataListObject.groupTotals[ind] = data['total'];
        dataListObject.charges[ind] = data['total_charge_amount'];
        dataListObject.payments[ind] = data['total_payment_amount'];
        dataListObject.Adjustments[ind] = data['total_adjustment_amount'];

        transformedData[data[groupColumn]] = dataListObject;
        
    });
    return transformedData;
}
const transformedData = transform(originalData);

const flatTransformedData = Object.keys(transformedData).map(groupCol => {
    const values = transformedData[groupCol];
    return Object.keys(values).map(col => {
        let hierarchyArray = [];
        switch (col) {
            case 'groupTotals':
                hierarchyArray = [groupCol];
                break;
            case 'charges':
                hierarchyArray = [groupCol, 'Charges'];
                break;
            case 'payments':
                hierarchyArray = [groupCol, 'Payments'];
                break;
            case 'Adjustments':
                hierarchyArray = [groupCol, 'Adjustments'];
                break;
            default:
                break;
        }
        return new Tree(hierarchyArray, ...values[col]);
    });
}).reduce((agg, treeListOfList) =>  [...agg, ...treeListOfList], []);

console.log(flatTransformedData);