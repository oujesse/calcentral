package edu.berkeley.calcentral.daos;

import com.google.common.collect.Maps;
import edu.berkeley.calcentral.domain.User;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.BeanPropertyRowMapper;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Repository;

import javax.sql.DataSource;
import java.util.Map;

@Repository
public class UserDataDao {

	@Autowired @Qualifier("dataSource")
	private DataSource dataSource;

	@Autowired
	private WidgetDataDao widgetDataDao;

	public User get(String uid) {
		Map<String, String> params = Maps.newHashMap();
		params.put("uid", uid);

		NamedParameterJdbcTemplate queryRunner = new NamedParameterJdbcTemplate(dataSource);
		User user = null;
		try {
			user = queryRunner.queryForObject(SqlQueries.get, params, new BeanPropertyRowMapper<User>(User.class));
		} catch (EmptyResultDataAccessException e) {
			return null;
		}

		return user;
	}

	public void update(User user) {
		//TODO: fill me in
	}

	public void delete(String uid) {
		//TODO: fill me in    
	}

	private static class SqlQueries {
		static String get = " SELECT uid, firstname, lastname FROM calcentral_users WHERE uid = :uid";
	}
}
