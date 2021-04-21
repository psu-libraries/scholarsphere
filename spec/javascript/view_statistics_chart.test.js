import multiFormat from '../../app/javascript/frontend/scripts/view_statistics_chart'

describe('ViewStatisticsChart', () => {
  it('formats a day tick properly', () => {
    const formattedDate = multiFormat(new Date('2021-04-13 00:00:00'))

    expect(formattedDate).toBe('Tue 13')
  })

  it('formats a month tick properly', () => {
    const formattedDate = multiFormat(new Date('2020-12-01 00:00:00'))

    expect(formattedDate).toBe('Dec')
  })

  it('formats a year tick properly', () => {
    const formattedDate = multiFormat(new Date('2021-01-01 00:00:00'))

    expect(formattedDate).toBe('2021')
  })
})
